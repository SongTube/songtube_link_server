import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lan_scanner/lan_scanner.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:songtube_link_desktop/main.dart';

// Server port
const _port = 1458;

// Global HTTP Bind
HttpServer? linkServer;

class LinkServer {

  static void listenToServer() {
    if (linkServer != null) {
      linkServer!.listen((request) async {
        request.response.headers.add("Access-Control-Allow-Origin", "*");
        request.response.headers.add("Access-Control-Allow-Methods", "POST,GET,DELETE,PUT,OPTIONS");
        request.response.statusCode = HttpStatus.ok;
        // Reply with an unique message
        if (request.uri.path == '/ping') {
          request.response.write("pong");
          request.response.close();
        }
        // Retrieve the detected device with SongTube
        if (request.uri.path == '/detect') {
          // Check LAN IP
          String? wifiIP;
          try {
            wifiIP = await NetworkInfo().getWifiIP();
          } catch (_) {
            wifiIP = null;
          }
          var subnet = wifiIP != null ? ipToCSubnet(wifiIP) : '192.168.1';
          // Fetch list of hosts in local network
          final scanner = LanScanner();
          final Completer completer = Completer();
          bool done = false;
          scanner.icmpScan(subnet, progressCallback: (value) {}).listen((host) async {
            // Check if this host is SongTube
            try {
              final reply = await http.post(Uri.parse('http://${host.ip}:1458/connect'));
              final jsonMap = jsonDecode(reply.body);
              if (kDebugMode) {
                print('Found SongTube on ${host.ip}');
              }
              final jsonBody = jsonEncode({"name": jsonMap['name'], "host": host.ip});
              request.response.headers.add("Content-Type", "application/json");
              request.response.write(jsonBody);
              request.response.close();
              done = true;
            } catch (_) {
              if (kDebugMode) {
                print('Host ${host.ip} is not SongTube');
                print(_.toString());
              }
            }
          }).onDone(() {
            completer.complete();
          });
          await completer.future;
          if (done) {
            return;
          } else {
            // SongTube was not Detected
            request.response.write('notfound');
            request.response.close();
          }

        }
      });
    }
  }

  static Future<void> initialize(bool autoStart) async {
    linkServer = await HttpServer.bind(InternetAddress.tryParse('0.0.0.0'), _port);
    if (linkServer == null) {
      return;
    }
    if (kDebugMode) {
      print("Server running on IP : ${linkServer!.address} On Port : ${linkServer!.port}");
    }
    listenToServer();
    runTray(autoStart);
  }

}