import 'dart:async';
import 'dart:io';

class UDPUtil {
  UDPUtil() {
    init();
  }
  final _udpSocket = Completer<RawDatagramSocket>();

  Future<RawDatagramSocket> get udpSocket => _udpSocket.future;

  Future<void> init() async {
    final socket = await RawDatagramSocket.bind('127.0.0.1', 12300);

    _udpSocket.complete(socket);
    print(
        'UDP socket is bound to ${(socket).address.address}:${(socket).port}');

    socket.listen(
      (RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = socket.receive();
          if (datagram != null) {
            String message = String.fromCharCodes(datagram.data);
            print('Received message: $message');
          }
        }
      },
    );
  }

  Future<void> sendPackage() async {
    (await udpSocket).send(
        'v1&&Hello, UDP!&&${DateTime.now().toUtc().toIso8601String()}'
            .codeUnits,
        InternetAddress('127.0.0.1'),
        12345);
  }
}
