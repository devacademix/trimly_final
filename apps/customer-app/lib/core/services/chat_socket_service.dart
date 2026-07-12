import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/env.dart';
import '../models/chat.dart';
import '../storage/secure_storage.dart';

/// Thin wrapper around the Socket.IO connection to the chat gateway.
/// Authenticates via the same access token used for REST calls (see
/// ChatGateway.handleConnection on the backend) — the server derives the
/// sender from the authenticated socket, never from the message payload.
class ChatSocketService {
  final SecureStorage secureStorage;

  ChatSocketService({required this.secureStorage});

  io.Socket? _socket;
  final _messageController = StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get messages => _messageController.stream;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await secureStorage.accessToken;
    if (token == null) return;

    _socket?.dispose();
    _socket = io.io(
      Env.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnectError((err) => debugPrint('[CHAT] connect error: $err'));
    _socket!.on('message_received', (data) {
      try {
        _messageController.add(ChatMessage.fromJson(Map<String, dynamic>.from(data as Map)));
      } catch (e) {
        debugPrint('[CHAT] failed to parse incoming message: $e');
      }
    });

    _socket!.connect();
  }

  void joinRoom(String roomId) {
    _socket?.emit('join_room', {'roomId': roomId});
  }

  void sendMessage(String roomId, String text) {
    _socket?.emit('send_message', {'roomId': roomId, 'text': text});
  }

  void disconnect() {
    _socket?.disconnect();
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
