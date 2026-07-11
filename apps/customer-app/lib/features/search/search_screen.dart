import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _selectedGender = 'Any';
  double _maxDistance = 10.0;
  double _minRating = 4.0;
  RangeValues _priceRange = const RangeValues(100, 2000);

  final List<Map<String, dynamic>> _allSalons = [
    {
      'id': '1',
      'name': 'Glow & Style Lounge',
      'category': 'Hair & Makeup',
      'rating': 4.8,
      'distance': 1.2,
      'price': 499,
      'gender': 'Women Only',
      'image': 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=500&auto=format&fit=crop&q=60',
      'address': 'MG Road, Bangalore',
    },
    {
      'id': '2',
      'name': 'The Dapper Men Salon',
      'category': 'Men\'s Grooming',
      'rating': 4.9,
      'distance': 2.5,
      'price': 299,
      'gender': 'Men Only',
      'image': 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=500&auto=format&fit=crop&q=60',
      'address': 'Indiranagar, Bangalore',
    },
    {
      'id': '3',
      'name': 'Urban Spa & Nails',
      'category': 'Spa & Nails',
      'rating': 4.7,
      'distance': 3.1,
      'price': 999,
      'gender': 'Unisex',
      'image': 'https://images.unsplash.com/photo-1600334089648-b0d9d3028eb2?w=500&auto=format&fit=crop&q=60',
      'address': 'Koramangala, Bangalore',
    },
  ];

  List<Map<String, dynamic>> _filteredSalons = [];

  @override
  void initState() {
    super.initState();
    _filteredSalons = List.from(_allSalons);
  }

  void _applyFilters() {
    setState(() {
      _filteredSalons = _allSalons.where((salon) {
        final query = _searchController.text.toLowerCase();
        final matchesQuery = salon['name'].toString().toLowerCase().contains(query) ||
            salon['category'].toString().toLowerCase().contains(query);

        final matchesDistance = salon['distance'] <= _maxDistance;
        final matchesRating = salon['rating'] >= _minRating;
        final matchesPrice = salon['price'] >= _priceRange.start && salon['price'] <= _priceRange.end;

        bool matchesGender = true;
        if (_selectedGender == 'Men Only') {
          matchesGender = salon['gender'] == 'Men Only' || salon['gender'] == 'Unisex';
        } else if (_selectedGender == 'Women Only') {
          matchesGender = salon['gender'] == 'Women Only' || salon['gender'] == 'Unisex';
        }

        return matchesQuery && matchesDistance && matchesRating && matchesPrice && matchesGender;
      }).toList();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Distance
                  Text('Max Distance: ${_maxDistance.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 20,
                    onChanged: (val) {
                      setModalState(() {
                        _maxDistance = val;
                      });
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Rating
                  Text('Minimum Rating: ${_minRating.toStringAsFixed(1)} ★', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _minRating,
                    min: 3,
                    max: 5,
                    divisions: 4,
                    onChanged: (val) {
                      setModalState(() {
                        _minRating = val;
                      });
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Price
                  Text('Price Range: ₹${_priceRange.start.toStringAsFixed(0)} - ₹${_priceRange.end.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  RangeSlider(
                    values: _priceRange,
                    min: 100,
                    max: 3000,
                    onChanged: (val) {
                      setModalState(() {
                        _priceRange = val;
                      });
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Gender Preference
                  const Text('Gender Preference', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Any', 'Men Only', 'Women Only'].map((gender) {
                      final isSelected = _selectedGender == gender;
                      return ChoiceChip(
                        label: Text(gender),
                        selected: isSelected,
                        onSelected: (val) {
                          setModalState(() {
                            _selectedGender = gender;
                          });
                          _applyFilters();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Apply & Show Results'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Discovery'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Input Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: 'Search salons or services...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.mic_none_outlined),
                        onPressed: () {}, // Voice search simulation trigger
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.tune, color: theme.colorScheme.primary),
                    onPressed: _showFilterBottomSheet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Results List
            Expanded(
              child: _filteredSalons.isEmpty
                  ? const Center(
                      child: Text(
                        'No salons found matching your criteria.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filteredSalons.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final salon = _filteredSalons[index];
                        return GestureDetector(
                          onTap: () {
                            context.push('/salon-details', extra: salon);
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 1,
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    salon['image'],
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          salon['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${salon['category']} • ${salon['distance']} km',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              salon['rating'].toString(),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            const Spacer(),
                                            Text(
                                              'From ₹${salon['price']}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
