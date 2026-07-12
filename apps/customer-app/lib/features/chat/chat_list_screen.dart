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
      appBar: AppBar(title: const Text('Messages')),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load messages: $error', style: const TextStyle(color: Colors.grey))),
        data: (rooms) {
          if (rooms.isEmpty) {
            return const Center(
              child: Text('No conversations yet. Message a salon from its profile page.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(chatRoomsProvider),
            child: ListView.separated(
              itemCount: rooms.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final room = rooms[index];
                final other = currentUserId != null ? room.otherParticipant(currentUserId) : null;
                final name = other?.fullName ?? 'Salon';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: other?.profileImageUrl != null ? NetworkImage(other!.profileImageUrl!) : null,
                    child: other?.profileImageUrl == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?') : null,
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/chat/${room.id}', extra: name),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
