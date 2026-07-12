import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/booking.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/data_providers.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> with SingleTickerProviderStateMixin {
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

  Future<void> _cancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Go Back')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(bookingRepositoryProvider).cancelBooking(booking.id);
      ref.invalidate(myBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled')));
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : 'Failed to cancel booking';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _rescheduleBooking(Booking booking) async {
    final date = await showDatePicker(
      context: context,
      initialDate: booking.startTime.isAfter(DateTime.now()) ? booking.startTime : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(booking.startTime));
    if (time == null || !mounted) return;

    final newStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    try {
      await ref.read(bookingRepositoryProvider).rescheduleBooking(booking.id, newStart);
      ref.invalidate(myBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking rescheduled')));
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : 'Failed to reschedule booking';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load bookings: $error')),
        data: (bookings) {
          final upcoming = bookings.where((b) => b.status == BookingStatus.pending || b.status == BookingStatus.confirmed).toList();
          final completed = bookings.where((b) => b.status == BookingStatus.completed).toList();
          final cancelled = bookings.where((b) => b.status == BookingStatus.cancelled || b.status == BookingStatus.noShow).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsTabList(upcoming),
              _buildBookingsTabList(completed),
              _buildBookingsTabList(cancelled),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingsTabList(List<Booking> list) {
    final theme = Theme.of(context);

    if (list.isEmpty) {
      return const Center(child: Text('No bookings found.', style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myBookingsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final booking = list[index];
          final isUpcoming = booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed;
          final isCompleted = booking.status == BookingStatus.completed;

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          booking.tenantName ?? 'Salon',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Text(
                        '₹${booking.totalPrice.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    booking.staffName != null ? '${booking.serviceName} • with ${booking.staffName}' : booking.serviceName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        '${booking.startTime.day}/${booking.startTime.month}/${booking.startTime.year} at ${TimeOfDay.fromDateTime(booking.startTime).format(context)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (isUpcoming) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _cancelBooking(booking),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _rescheduleBooking(booking),
                            child: const Text('Reschedule'),
                          ),
                        ),
                      ],
                    ),
                  ] else if (isCompleted) ...[
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reviews are coming soon')),
                        );
                      },
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 36)),
                      child: const Text('Write a Review'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
