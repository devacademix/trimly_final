import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SalonDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> salon;

  const SalonDetailsScreen({super.key, required this.salon});

  @override
  State<SalonDetailsScreen> createState() => _SalonDetailsScreenState();
}

class _SalonDetailsScreenState extends State<SalonDetailsScreen> {
  int _selectedStaffIndex = 0;
  String? _selectedService;
  double _selectedServicePrice = 0.0;

  final List<Map<String, dynamic>> _staffList = [
    {
      'id': 's1',
      'name': 'Alex Rivera',
      'role': 'Hair Specialist',
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=60',
    },
    {
      'id': 's2',
      'name': 'Mia Chen',
      'role': 'Nail Artist',
      'avatar': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=60',
    },
    {
      'id': 's3',
      'name': 'Rohan Das',
      'role': 'Skin Care Expert',
      'avatar': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=60',
    },
  ];

  final List<Map<String, dynamic>> _services = [
    {
      'id': 'srv1',
      'name': 'Classic Haircut',
      'price': 499.0,
      'duration': '30 min',
      'description': 'Premium haircut completed by top salon specialists, including wash & dry.',
    },
    {
      'id': 'srv2',
      'name': 'Beard Grooming & Shave',
      'price': 299.0,
      'duration': '20 min',
      'description': 'Precision trimming, styling, hot towel shave, and beard oil treatment.',
    },
    {
      'id': 'srv3',
      'name': 'Hydrating Facial',
      'price': 999.0,
      'duration': '45 min',
      'description': 'Exfoliation, steam, gentle extraction, massage, and deep hydrating mask.',
    },
    {
      'id': 'srv4',
      'name': 'Gel Manicure',
      'price': 799.0,
      'duration': '40 min',
      'description': 'Nail shaping, cuticle care, gel color application, and nourishing massage.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible AppBar with Salon Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.salon['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.salon['image'],
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black87],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details List
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle & ratings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.salon['category'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              widget.salon['rating'].toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.salon['address'],
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    // Staff List Section
                    const Text(
                      'Select Specialist',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _staffList.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final staff = _staffList[index];
                          final isSelected = _selectedStaffIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedStaffIndex = index;
                              });
                            },
                            child: Container(
                              width: 100,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary.withOpacity(0.08)
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(staff['avatar']),
                                    radius: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    staff['name'].split(' ')[0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 32),

                    // Services Section
                    const Text(
                      'Our Services',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _services.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final srv = _services[index];
                        final isSelected = _selectedService == srv['id'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedService = srv['id'];
                              _selectedServicePrice = srv['price'];
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withOpacity(0.04)
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      srv['name'],
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '₹${srv['price'].toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      srv['duration'],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  srv['description'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 100), // padding for checkout action bar
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      bottomSheet: _selectedService == null
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Price',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        Text(
                          '₹${_selectedServicePrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.push('/booking', extra: {
                          'salon': widget.salon,
                          'staff': _staffList[_selectedStaffIndex],
                          'service': _services.firstWhere((element) => element['id'] == _selectedService),
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Book Slot',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
