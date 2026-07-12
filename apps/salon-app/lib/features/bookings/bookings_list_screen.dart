import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/booking.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/data_providers.dart';

class BookingsListScreen extends ConsumerStatefulWidget {
  const BookingsListScreen({super.key});

  @override
  ConsumerState<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends ConsumerState<BookingsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(Booking booking, BookingStatus status) async {
    try {
      await ref.read(bookingRepositoryProvider).updateStatus(booking.id, status);
      ref.invalidate(bookingsListProvider);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : 'Failed to update booking';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Manage Appointments', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.blueGrey,
          indicatorColor: const Color(0xFF6366F1),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
        error: (error, _) => Center(
          child: Text('Could not load bookings: $error', style: const TextStyle(color: Colors.blueGrey)),
        ),
        data: (bookings) {
          final pending = bookings.where((b) => b.status == BookingStatus.pending).toList();
          final confirmed = bookings.where((b) => b.status == BookingStatus.confirmed).toList();
          final completed = bookings.where((b) => b.status == BookingStatus.completed).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsTabList(pending),
              _buildBookingsTabList(confirmed),
              _buildBookingsTabList(completed),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingsTabList(List<Booking> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text('No appointments in this category.', style: TextStyle(color: Colors.blueGrey)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(bookingsListProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final booking = list[index];
          final isPending = booking.status == BookingStatus.pending;
          final isConfirmed = booking.status == BookingStatus.confirmed;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueGrey.shade800),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking.customerName ?? 'Customer',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    Text(
                      '₹${booking.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(booking.serviceName, style: const TextStyle(color: Colors.blueGrey, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${TimeOfDay.fromDateTime(booking.startTime).format(context)}'
                        '${booking.staffName != null ? ' • Specialist: ${booking.staffName}' : ''}',
                        style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                if (isPending) ...[
                  const Divider(height: 24, color: Colors.blueGrey),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateStatus(booking, BookingStatus.cancelled),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            foregroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateStatus(booking, BookingStatus.confirmed),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                ] else if (isConfirmed) ...[
                  const Divider(height: 24, color: Colors.blueGrey),
                  ElevatedButton(
                    onPressed: () => _updateStatus(booking, BookingStatus.completed),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Mark as Completed'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
