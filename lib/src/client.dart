import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:awaitws/awaitws.dart';
import 'package:web_socket_channel/io.dart';
import 'package:mutex/mutex.dart';

class AwaitClient {
  IOWebSocketChannel channel;
  int nextID;
  HashMap<int, Completer<AwaitedResponse>> waitingResponses;
  Mutex mutex;

  AwaitClient(IOWebSocketChannel channel) {
    this.channel = channel;
    nextID = 0;
    waitingResponses = HashMap<int, Completer<AwaitedResponse>>();
    mutex = Mutex();
  }

  Future<AwaitedResponse> request(dynamic message) async {
    var completer = Completer<AwaitedResponse>();

    var id = await newWaitingResponse(completer);
    channel.sink.add(jsonEncode({
      'id': id,
      'request': true,
      'message': message,
    }));

    return completer.future;
  }

  Future<int> newWaitingResponse(Completer<AwaitedResponse> completer) async {
    await mutex.acquire();

    var id = nextID;
    nextID++;

    waitingResponses[id] = completer;

    mutex.release();

    return id;
  }

  bool isRequest(Map<String, dynamic> message) {
    if (!message.containsKey('request')) {
      return false;
    }

    if (!(message['request'] is bool)) {
      return false;
    }

    return message['request'] as bool;
  }

  bool handleResponse(Map<String, dynamic> message) {
    if (!message.containsKey('response')) {
      return false;
    }

    if (!(message['response'] is bool)) {
      return false;
    }

    if (!(message['response'] as bool)) {
      return false;
    }

    if (!message.containsKey('id')) {
      return false;
    }

    if (!(message['id'] is int)) {
      return false;
    }

    var id = message['id'] as int;

    waitingResponses[id].complete(AwaitedResponse(message, null));

    waitingResponses.remove(id);

    return true;
  }

  void respond(Map<String, dynamic> request, dynamic response) {
    if (!request.containsKey('id')) {
      return;
    }

    if (!(request['id'] is int)) {
      return;
    }

    channel.sink.add(jsonEncode({
      'id': request['id'] as int,
      'response': true,
      'message': response,
    }));
  }
}
