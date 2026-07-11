import 'package:flutter/material.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _myBookings = [
    {
      'id': 'b101',
      'salonName': 'Glow & Style Lounge',
      'service': 'Classic Haircut',
      'date': 'Tomorrow',
      'time': '10:00 AM',
      'price': '₹499',
      'status': 'Upcoming',
      'specialist': 'Alex Rivera',
    },
    {
      'id': 'b102',
      'salonName': 'The Dapper Men Salon',
      'service': 'Beard Grooming & Shave',
      'date': 'July 15, 2026',
      'time': '03:00 PM',
      'price': '₹299',
      'status': 'Upcoming',
      'specialist': 'Rohan Das',
    },
    {
      'id': 'b103',
      'salonName': 'Urban Spa & Nails',
      'service': 'Gel Manicure',
      'date': 'Yesterday',
      'time': '02:00 PM',
      'price': '₹799',
      'status': 'Completed',
      'specialist': 'Mia Chen',
    },
    {
      'id': 'b104',
      'salonName': 'Glow & Style Lounge',
      'service': 'Hydrating Facial',
      'date': 'July 1, 2026',
      'time': '11:00 AM',
      'price': '₹999',
      'status': 'Cancelled',
      'specialist': 'Rohan Das',
      'refundStatus': 'Refunded to Wallet',
    },
  ];

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

  void _showCancelDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment? A refund will be credited to your wallet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                booking['status'] = 'Cancelled';
                booking['refundStatus'] = 'Pending';
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(Map<String, dynamic> booking) {
    double rating = 5;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How was your experience?', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  return IconButton(
                    icon: Icon(
                      starVal <= rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setModalState(() {
                        rating = starVal.toDouble();
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Share details of your experience...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review submitted! Thank you.')),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upcomingList = _myBookings.where((b) => b['status'] == 'Upcoming').toList();
    final completedList = _myBookings.where((b) => b['status'] == 'Completed').toList();
    final cancelledList = _myBookings.where((b) => b['status'] == 'Cancelled').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          tabs: [
            Tab(text: 'Upcoming (${upcomingList.length})'),
            Tab(text: 'Completed (${completedList.length})'),
            Tab(text: 'Cancelled (${cancelledList.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsTabList(upcomingList),
          _buildBookingsTabList(completedList),
          _buildBookingsTabList(cancelledList),
        ],
      ),
    );
  }

  Widget _buildBookingsTabList(List<Map<String, dynamic>> list) {
    final theme = Theme.of(context);

    if (list.isEmpty) {
      return const Center(
        child: Text(
          'No bookings found.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking = list[index];
        final isUpcoming = booking['status'] == 'Upcoming';
        final isCompleted = booking['status'] == 'Completed';

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking['salonName']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      booking['price']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${booking['service']} • with ${booking['specialist']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${booking['date']} at ${booking['time']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                if (booking['refundStatus'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        'Refund: ${booking['refundStatus']}',
                        style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 24),
                if (isUpcoming) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showCancelDialog(booking),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Rescheduling Portal Opened')),
                            );
                          },
                          child: const Text('Reschedule'),
                        ),
                      ),
                    ],
                  ),
                ] else if (isCompleted) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invoice Download Triggered')),
                            );
                          },
                          child: const Text('Invoice'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showReviewDialog(booking),
                          child: const Text('Review'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Starting fresh booking flow')),
                      );
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 36)),
                    child: const Text('Rebook Service'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
