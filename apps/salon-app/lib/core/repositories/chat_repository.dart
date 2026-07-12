import 'package:dio/dio.dart';
import '../models/chat.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

class ChatRepository {
  final ApiClient apiClient;

  ChatRepository({required this.apiClient});

  Future<List<ChatRoom>> getRooms() async {
    try {
      final response = await apiClient.dio.get('/chat/rooms');
      final list = response.data['data'] as List;
      return list.map((json) => ChatRoom.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ChatRoom> startRoom(String recipientId) async {
    try {
      final response = await apiClient.dio.post('/chat/rooms', data: {'recipientId': recipientId});
      return ChatRoom.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<ChatMessage>> getMessages(String roomId) async {
    try {
      final response = await apiClient.dio.get('/chat/rooms/$roomId/messages');
      final list = response.data['data'] as List;
      return list.map((json) => ChatMessage.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
