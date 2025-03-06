import 'dart:io';
import 'dart:typed_data';

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
    final uri = request.uri;
    // Upgrade to WebSocket.
    WebSocket webSocket = await WebSocketTransformer.upgrade(request);
    print("🔗 New client connected from ${request.connectionInfo?.remoteAddress}");

    // Check connection type by query parameter.
    final type = uri.queryParameters['type'] ?? 'audio';
    if (type == 'control') {
      // For control connections, just handle ping/pong.
      webSocket.listen(
        (data) {
          if (data is String && data.startsWith("ping:")) {
            final response = data.replaceFirst("ping", "pong");
            webSocket.add(response);
            print("💬 Ping received. Sent pong: $response");
          }
        },
        onDone: () {
          print("🔌 Control connection closed.");
        },
        onError: (error) {
          print("❌ Control connection error: $error");
        },
      );
      return;
    }

    // For audio connections, start aplay.
    final process = await Process.start(
      "aplay",
      ["-c", "1", "-f", "S16_LE", "-r", "44100", "-B", "1000", "-F", "250"],
    );

    // Monitor aplay's stdout and stderr.
    process.stdout.transform(SystemEncoding().decoder).listen((data) {
      print("aplay stdout: $data");
    });
    process.stderr.transform(SystemEncoding().decoder).listen((data) {
      print("aplay stderr: $data");
    });
    process.exitCode.then((code) {
      print("aplay process exited with code: $code");
    });

    // Listen for incoming messages from the WebSocket.
    webSocket.listen(
      (data) {
        // Only process binary data as audio.
        if (data is Uint8List) {
          print("🎵 Streaming audio data: ${data.length} bytes");
          process.stdin.add(data);
        } else {
          print("⚠️ Received non-binary data on audio connection.");
        }
      },
      onDone: () {
        print("🔌 Audio client disconnected.");
        process.stdin.close();
      },
      onError: (error) {
        print("❌ WebSocket error on audio connection: $error");
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
