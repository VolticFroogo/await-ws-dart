import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:awaitws/awaitws.dart';

void makeRequest(AwaitClient awaitClient) async {
  var response = await awaitClient.request('client');
  print(response.message['message']);
}

void main() {
  final channel = IOWebSocketChannel.connect('ws://localhost:8080/ws');

  var awaitClient = AwaitClient(channel);
  makeRequest(awaitClient);

  channel.stream.listen((message) {
    var request = jsonDecode(message);

    if (awaitClient.handleResponse(request)) {
      return;
    }

    if (awaitClient.isRequest(request)) {
      awaitClient.respond(request, 'Hello ' + request['message']);
    }
  });
}
