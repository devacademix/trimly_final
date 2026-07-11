import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SalonDashboardScreen extends StatefulWidget {
  const SalonDashboardScreen({super.key});

  @override
  State<SalonDashboardScreen> createState() => _SalonDashboardScreenState();
}

class _SalonDashboardScreenState extends State<SalonDashboardScreen> {
  bool _isShopOpen = true;

  final List<Map<String, dynamic>> _upcomingBookings = [
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
      'status': 'Pending Approval',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    Colors.emerald,
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

            // Today's Bookings List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _upcomingBookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = _upcomingBookings[index];
                final isPending = booking['status'] == 'Pending Approval';
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPending
                                  ? Colors.amber.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              booking['status']!,
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
                      Text(
                        booking['service']!,
                        style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 14),
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
                                '${booking['time']} • ${booking['specialist']}',
                                style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                              ),
                            ],
                          ),
                          Text(
                            booking['price']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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
                                onPressed: () {},
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
