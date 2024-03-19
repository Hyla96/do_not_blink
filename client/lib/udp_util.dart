import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:rxdart/rxdart.dart';

class UDPUtil {
  UDPUtil() {
    init();
  }
  final _udpSocket = Completer<RawDatagramSocket>();
  final port = Random().nextInt(50000) + 10000;

  final messagesCount = BehaviorSubject.seeded(0);

  Future<RawDatagramSocket> get udpSocket => _udpSocket.future;

  Future<void> init() async {
    final socket = await RawDatagramSocket.bind('127.0.0.1', port);

    _udpSocket.complete(socket);
    print(
        'UDP socket is bound to ${(socket).address.address}:${(socket).port}');

    socket.listen(
      (RawSocketEvent event) {
        final now = DateTime.now();
        if (event == RawSocketEvent.read) {
          Datagram? datagram = socket.receive();
          if (datagram != null) {
            final now = DateTime.now();
            String message = String.fromCharCodes(datagram.data);
            print('Received message: $message');
            final dateTimeMessage = message.split('&&').last;
            final dateTime = DateTime.parse(dateTimeMessage);
            messagesCount.add(messagesCount.value + 1);
            print(
                'Message returned in ${now.difference(dateTime).inMicroseconds}microseconds');
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
