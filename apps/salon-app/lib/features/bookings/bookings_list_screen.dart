import 'package:flutter/material.dart';

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _bookings = [
    {
      'id': 'b1',
      'customerName': 'Sarah Connor',
      'service': 'Classic Haircut & Styling',
      'time': '10:30 AM',
      'price': '₹499',
      'specialist': 'Alex Rivera',
      'status': 'Confirmed',
    },
    {
      'id': 'b2',
      'customerName': 'David Miller',
      'service': 'Beard Grooming & Shave',
      'time': '11:15 AM',
      'price': '₹299',
      'specialist': 'Rohan Das',
      'status': 'Confirmed',
    },
    {
      'id': 'b3',
      'customerName': 'Neha Sharma',
      'service': 'Gel Manicure',
      'time': '01:00 PM',
      'price': '₹799',
      'specialist': 'Mia Chen',
      'status': 'Pending',
    },
    {
      'id': 'b4',
      'customerName': 'John Wick',
      'service': 'Hair Wash & Styling',
      'time': 'Yesterday',
      'price': '₹399',
      'specialist': 'Alex Rivera',
      'status': 'Completed',
    },
    {
      'id': 'b5',
      'customerName': 'Emma Watson',
      'service': 'Hydrating Facial',
      'time': 'Yesterday',
      'price': '₹999',
      'specialist': 'Rohan Das',
      'status': 'Completed',
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

  @override
  Widget build(BuildContext context) {
    final pendingBookings = _bookings.where((b) => b['status'] == 'Pending').toList();
    final confirmedBookings = _bookings.where((b) => b['status'] == 'Confirmed').toList();
    final completedBookings = _bookings.where((b) => b['status'] == 'Completed').toList();

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
          tabs: [
            Tab(text: 'Pending (${pendingBookings.length})'),
            Tab(text: 'Confirmed (${confirmedBookings.length})'),
            Tab(text: 'Completed (${completedBookings.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsTabList(pendingBookings),
          _buildBookingsTabList(confirmedBookings),
          _buildBookingsTabList(completedBookings),
        ],
      ),
    );
  }

  Widget _buildBookingsTabList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'No appointments in this category.',
          style: TextStyle(color: Colors.blueGrey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final booking = list[index];
        final isPending = booking['status'] == 'Pending';
        final isConfirmed = booking['status'] == 'Confirmed';

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
                  Text(
                    booking['customerName']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    booking['price']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                booking['service']!,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text(
                        '${booking['time']} • Specialist: ${booking['specialist']}',
                        style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              if (isPending) ...[
                const Divider(height: 24, color: Colors.blueGrey),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            booking['status'] = 'Cancelled';
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            booking['status'] = 'Confirmed';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ] else if (isConfirmed) ...[
                const Divider(height: 24, color: Colors.blueGrey),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      booking['status'] = 'Completed';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Mark as Completed'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
