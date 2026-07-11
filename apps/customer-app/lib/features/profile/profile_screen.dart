import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;
  String _selectedLanguage = 'English';
  final double _walletBalance = 450.0;
  final int _loyaltyPoints = 280;

  final List<String> _savedAddresses = [
    'Home: Flat 402, Prestige Heights, Bangalore',
    'Work: Signet Ring Road, Tech Park, Bangalore',
  ];

  void _showAddAddressDialog() {
    final addressController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Saved Address'),
        content: TextField(
          controller: addressController,
          decoration: const InputDecoration(
            hintText: 'Enter address details...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (addressController.text.isNotEmpty) {
                setState(() {
                  _savedAddresses.add(addressController.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReferralDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Refer & Earn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard, size: 48, color: Colors.pink),
            const SizedBox(height: 12),
            const Text(
              'Share this code with friends to get ₹100 cashback when they complete their first booking!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'TRIMLY100',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Header
            Row(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=60'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sarah Jenkins',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'customer@trimly.test',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Wallet Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wallet Balance',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${_walletBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '$_loyaltyPoints Points',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings List
            _buildSectionHeader('Preferences'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: _darkMode,
                    onChanged: (val) {
                      setState(() {
                        _darkMode = val;
                      });
                    },
                    secondary: const Icon(Icons.dark_mode_outlined),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: const Text('Language'),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedLanguage = val;
                          });
                        }
                      },
                      items: ['English', 'Hindi'].map((lang) {
                        return DropdownMenuItem(value: lang, child: Text(lang));
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildSectionHeader('Saved Addresses'),
            Card(
              child: Column(
                children: [
                  ..._savedAddresses.map((addr) => ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(addr),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _savedAddresses.remove(addr);
                            });
                          },
                        ),
                      )),
                  ListTile(
                    leading: const Icon(Icons.add, color: Colors.blue),
                    title: const Text('Add New Address', style: TextStyle(color: Colors.blue)),
                    onTap: _showAddAddressDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildSectionHeader('Business & Promos'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.share_outlined),
                    title: const Text('Refer & Earn Program'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showReferralDialog,
                  ),
                  ListTile(
                    leading: const Icon(Icons.support_agent_outlined),
                    title: const Text('Help & Support Portal'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to Support
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support Portal Loaded')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout
            ElevatedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
