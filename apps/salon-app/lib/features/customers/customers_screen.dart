import 'package:flutter/material.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final List<Map<String, dynamic>> _customers = [
    {
      'id': 'c1',
      'name': 'Sarah Connor',
      'email': 'sarah@test.com',
      'visits': 8,
      'points': 450,
      'lastVisit': 'Yesterday',
      'notes': 'Prefers organic shampoos. Sensitive scalp.',
    },
    {
      'id': 'c2',
      'name': 'David Miller',
      'email': 'david@test.com',
      'visits': 3,
      'points': 150,
      'lastVisit': 'July 2, 2026',
      'notes': 'Always gets beard grooming with hot towels.',
    },
    {
      'id': 'c3',
      'name': 'Neha Sharma',
      'email': 'neha@test.com',
      'visits': 12,
      'points': 920,
      'lastVisit': 'June 28, 2026',
      'notes': 'Regular gel manicure customer.',
    },
  ];

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Walk-in Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Customer Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(hintText: 'Email Address'),
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
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _customers.add({
                    'id': 'c${_customers.length + 1}',
                    'name': nameController.text,
                    'email': emailController.text,
                    'visits': 1,
                    'points': 50,
                    'lastVisit': 'Today',
                    'notes': 'Walk-in registration.',
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Customers CRM', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: _showAddCustomerDialog,
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _customers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final customer = _customers[index];
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
                      Text(
                        customer['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${customer['points']} pts',
                          style: const TextStyle(
                            color: Color(0xFF818CF8),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer['email'],
                    style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Visits: ${customer['visits']}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        'Last: ${customer['lastVisit']}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF334155), height: 24),
                  Row(
                    children: [
                      const Icon(Icons.note_alt_outlined, color: Colors.blueGrey, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          customer['notes'],
                          style: const TextStyle(color: Colors.white60, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
