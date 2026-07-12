import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/booking.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/data_providers.dart';

class SalonDashboardScreen extends ConsumerStatefulWidget {
  const SalonDashboardScreen({super.key});

  @override
  ConsumerState<SalonDashboardScreen> createState() => _SalonDashboardScreenState();
}

class _SalonDashboardScreenState extends ConsumerState<SalonDashboardScreen> {
  bool _isShopOpen = true;

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
      backgroundColor: const Color(0xFF0F172A), // Slate Dark background
      appBar: AppBar(
        title: const Text('Trimly Business', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 1,
        actions: [
          Row(
            children: [
              Text(
                _isShopOpen ? 'Shop Open' : 'Shop Closed',
                style: TextStyle(
                  color: _isShopOpen ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Switch(
                value: _isShopOpen,
                activeColor: Colors.green,
                onChanged: (val) {
                  setState(() {
                    _isShopOpen = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Today\'s Bookings',
                    '12',
                    Icons.calendar_today,
                    Colors.indigoAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Today\'s Earnings',
                    '₹6,450',
                    Icons.currency_rupee,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMetricCard(
              'Active Specialists Working Now',
              '3 Staff Members',
              Icons.people_outline,
              Colors.amber,
              isWide: true,
            ),
            const SizedBox(height: 28),

            // Bookings Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Appointments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.push('/bookings-list');
                  },
                  child: const Text('Manage All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Upcoming bookings (pending/confirmed, soonest first)
            bookingsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Could not load bookings: $error', style: const TextStyle(color: Colors.blueGrey)),
              ),
              data: (bookings) {
                final upcoming = bookings
                    .where((b) => b.status == BookingStatus.pending || b.status == BookingStatus.confirmed)
                    .toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));
                final visible = upcoming.take(5).toList();

                if (visible.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No upcoming appointments.', style: TextStyle(color: Colors.blueGrey)),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visible.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = visible[index];
                    final isPending = booking.status == BookingStatus.pending;
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPending ? Colors.amber.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  booking.status.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isPending ? Colors.amber : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(booking.serviceName, style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 14)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${TimeOfDay.fromDateTime(booking.startTime).format(context)}'
                                    '${booking.staffName != null ? ' • ${booking.staffName}' : ''}',
                                    style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                                  ),
                                ],
                              ),
                              Text(
                                '₹${booking.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
                                    child: const Text('Accept'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isWide = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade800),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
