import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MoreHubScreen extends StatefulWidget {
  const MoreHubScreen({super.key});

  @override
  State<MoreHubScreen> createState() => _MoreHubScreenState();
}

class _MoreHubScreenState extends State<MoreHubScreen> {
  bool _isClockedIn = false;

  void _handleClockIn() {
    setState(() {
      _isClockedIn = !_isClockedIn;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isClockedIn ? 'Clocked in successfully at 10:00 AM!' : 'Clocked out successfully!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Operational Hub', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Staff Attendance Card (Quick clock in/out)
            Card(
              color: const Color(0xFF1E293B),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.watch_later_outlined, color: Colors.blueAccent, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Staff Attendance',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isClockedIn ? 'Status: Working' : 'Status: Clocked Out',
                            style: TextStyle(color: _isClockedIn ? Colors.green : Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _handleClockIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isClockedIn ? Colors.redAccent : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isClockedIn ? 'Clock Out' : 'Clock In'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI Business Assistant Premium Entry Card
            GestureDetector(
              onTap: () {
                context.push('/ai-assistant');
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'AI Business Assistant',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Forecasting revenue, suggested pricing, and peak hour predictions.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // More Features List
            _buildSectionHeader('Multi-Tenant SaaS Controls'),
            _buildHubListTile(Icons.storefront, 'Branch List & Analytics', 'Manage Koramangala and Indiranagar branches'),
            _buildHubListTile(Icons.inventory_2_outlined, 'Inventory Tracking', '4 Products low in stock alerts'),
            _buildHubListTile(Icons.account_balance_outlined, 'Payroll & Commission rules', 'Review staff monthly splits'),
            _buildHubListTile(Icons.assignment_ind_outlined, 'Role-Based Permissions', 'Define Receptionist and Manager rules'),
            const SizedBox(height: 24),

            // Logout Business
            ElevatedButton(
              onPressed: () {
                context.go('/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Logout Business Session', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
        child: Text(
          title,
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildHubListTile(IconData icon, String title, String subtitle) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6366F1)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.blueGrey, size: 18),
        onTap: () {},
      ),
    );
  }
}
