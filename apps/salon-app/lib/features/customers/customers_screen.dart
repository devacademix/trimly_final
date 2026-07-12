import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/salon_customer.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/data_providers.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _messageCustomer(BuildContext context, WidgetRef ref, SalonCustomer customer) async {
    try {
      final room = await ref.read(chatRepositoryProvider).startRoom(customer.id);
      if (context.mounted) context.push('/chat/${room.id}', extra: customer.displayName);
    } catch (e) {
      if (context.mounted) {
        final message = e is ApiException ? e.message : 'Failed to start conversation';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(salonCustomersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Customers CRM', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () => context.push('/chat')),
        ],
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
        error: (error, _) => Center(
          child: Text('Could not load customers: $error', style: const TextStyle(color: Colors.blueGrey)),
        ),
        data: (customers) {
          if (customers.isEmpty) {
            return const Center(
              child: Text('No customers yet — they\'ll show up here after their first booking.', style: TextStyle(color: Colors.blueGrey)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(salonCustomersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: customers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildCustomerCard(context, ref, customers[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, WidgetRef ref, SalonCustomer customer) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    customer.displayName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${customer.visits} visit${customer.visits == 1 ? '' : 's'}',
                    style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            if (customer.email != null || customer.phone != null) ...[
              const SizedBox(height: 4),
              Text(customer.email ?? customer.phone!, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last visit: ${_formatDate(customer.lastVisit)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                TextButton.icon(
                  onPressed: () => _messageCustomer(context, ref, customer),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF818CF8)),
                  label: const Text('Message', style: TextStyle(color: Color(0xFF818CF8))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
