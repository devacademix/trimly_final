import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/data_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(chatRoomsProvider);
    final currentUserId = ref.watch(authControllerProvider).user?.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
        error: (error, _) => Center(child: Text('Could not load messages: $error', style: const TextStyle(color: Colors.blueGrey))),
        data: (rooms) {
          if (rooms.isEmpty) {
            return const Center(
              child: Text('No conversations yet. Message a customer from their profile.', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(chatRoomsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rooms.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final room = rooms[index];
                final other = currentUserId != null ? room.otherParticipant(currentUserId) : null;
                final name = other?.fullName ?? 'Customer';
                return Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFF334155)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6366F1),
                      backgroundImage: other?.profileImageUrl != null ? NetworkImage(other!.profileImageUrl!) : null,
                      child: other?.profileImageUrl == null
                          ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white))
                          : null,
                    ),
                    title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.blueGrey),
                    onTap: () => context.push('/chat/${room.id}', extra: name),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
