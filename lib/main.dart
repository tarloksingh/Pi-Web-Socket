import 'dart:io';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';

const int serverPort = 8080;

void main() async {
  final localIp = await getLocalIP();
  print("✅ WebSocket Server started on ws://$localIp:$serverPort");

  final server = await HttpServer.bind(InternetAddress.anyIPv4, serverPort);
  print("🚀 Listening for WebSocket connections on port $serverPort");

  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      handleClient(request);
    } else {
      print("❌ Rejected non-WebSocket request.");
      request.response.statusCode = HttpStatus.forbidden;
      request.response.close();
    }
  }
}

void handleClient(HttpRequest request) async {
  try {
    WebSocket webSocket = await WebSocketTransformer.upgrade(request);
    print("🔗 New client connected from ${request.connectionInfo?.remoteAddress}");

    // Start aplay with tuned buffer settings: lower buffer (-B) and period (-F) times.
    final process = await Process.start(
      "aplay",
      ["-c", "1", "-f", "S16_LE", "-r", "16000", "-B", "2000", "-F", "500"],
    );

    // Monitor aplay's stdout and stderr to verify it is receiving data.
    process.stdout.transform(SystemEncoding().decoder).listen((data) {
      print("aplay stdout: $data");
    });
    process.stderr.transform(SystemEncoding().decoder).listen((data) {
      print("aplay stderr: $data");
    });
    process.exitCode.then((code) {
      print("aplay process exited with code: $code");
    });

    // Listen for incoming audio data from the WebSocket.
    webSocket.listen(
      (data) {
        if (data is Uint8List) {
          print("🎵 Streaming audio data: ${data.length} bytes");
          process.stdin.add(data);
        }
      },
      onDone: () {
        print("🔌 Client disconnected.");
        process.stdin.close();
      },
      onError: (error) {
        print("❌ WebSocket error: $error");
      },
    );
  } catch (e) {
    print("❌ Error handling client connection: $e");
  }
}

Future<String> getLocalIP() async {
  List<NetworkInterface> interfaces = await NetworkInterface.list();
  for (var interface in interfaces) {
    for (var addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
        return addr.address;
      }
    }
  }
  return "127.0.0.1";
}
