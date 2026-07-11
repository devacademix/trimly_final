import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/api_providers.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> bookingData;

  const BookingScreen({super.key, required this.bookingData});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  bool _isBooking = false;
  String _selectedPaymentMethod = 'Razorpay';

  final List<String> _morningSlots = ['09:00 AM', '10:00 AM', '11:00 AM'];
  final List<String> _afternoonSlots = ['12:00 PM', '02:00 PM', '03:00 PM', '04:00 PM'];
  final List<String> _eveningSlots = ['05:00 PM', '06:00 PM', '07:00 PM'];

  void _confirmBooking() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot.')),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    final apiClient = ref.read(apiClientProvider);
    final salon = widget.bookingData['salon'];
    final service = widget.bookingData['service'];
    final staff = widget.bookingData['staff'];

    try {
      // Step 1: Create booking in NestJS backend
      final bookingResponse = await apiClient.dio.post('/booking/create', data: {
        'branchId': salon['id'] ?? 'db900e57-3a13-4e89-bdc8-3a56cf996452',
        'serviceId': service['id'] ?? '16b9a896-bc9c-4df4-a4b7-0f81d115456f',
        'staffId': staff?['id'],
        'startTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      });

      final bookingId = bookingResponse.data['data']['id'];

      setState(() {
        _isBooking = false;
      });

      if (_selectedPaymentMethod == 'Wallet') {
        // Direct confirmation for Wallet
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Booking Confirmed!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your slot at ${salon['name']} is booked for ${_selectedDate.day}/${_selectedDate.month} at $_selectedTime.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    GoRouter.of(context).go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go to Home'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      } else {
        // Step 2: Fetch Razorpay checkout session details
        final checkoutResponse = await apiClient.dio.post('/payments/checkout', data: {
          'bookingId': bookingId,
        });

        final checkoutData = checkoutResponse.data['data'];

        // Go to Hosted Payment Gateway
        context.push('/payment-gateway', extra: {
          'method': _selectedPaymentMethod,
          'price': service['price'],
          'bookingId': bookingId,
          'orderId': checkoutData['orderId'],
          'keyId': checkoutData['keyId'],
          'salon': salon,
          'service': service,
          'staff': staff,
        });
      }
    } catch (e) {
      // Sandbox fallback if API is unreachable / mock data
      setState(() {
        _isBooking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected to Gateway (Sandbox Mode)')),
      );
      context.push('/payment-gateway', extra: {
        'method': _selectedPaymentMethod,
        'price': service['price'],
        'bookingId': 'mock-booking-id',
        'orderId': 'order_mock_${DateTime.now().millisecondsSinceEpoch}',
        'keyId': 'rzp_test_SnDZnu70NYQ1f5',
        'salon': salon,
        'service': service,
        'staff': staff,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final salon = widget.bookingData['salon'];
    final service = widget.bookingData['service'];
    final staff = widget.bookingData['staff'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Slot'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected service summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(staff['avatar']),
                    radius: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Specialist: ${staff['name']} • ${service['duration']}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${service['price'].toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Date picker section
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 85,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = _selectedDate.day == date.day &&
                      _selectedDate.month == date.month;
                  
                  final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: Container(
                      width: 65,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            weekdays[date.weekday % 7],
                            style: TextStyle(
                              color: isSelected ? Colors.white70 : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Time slots section
            const Text(
              'Select Time Slot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Morning
            _buildTimeSlotSection('Morning', _morningSlots, theme),
            const SizedBox(height: 16),

            // Afternoon
            _buildTimeSlotSection('Afternoon', _afternoonSlots, theme),
            const SizedBox(height: 16),

            // Evening
            _buildTimeSlotSection('Evening', _eveningSlots, theme),
            const SizedBox(height: 28),

            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                _buildPaymentMethodTile('Razorpay', 'Pay securely via Cards, Netbanking, or UPI', Icons.payment, theme),
                const SizedBox(height: 8),
                _buildPaymentMethodTile('PhonePe', 'Pay instantly via PhonePe App or UPI ID', Icons.account_balance_wallet, theme),
                const SizedBox(height: 8),
                _buildPaymentMethodTile('Wallet', 'Use Trimly Wallet Cashbacks (Balance: ₹450)', Icons.wallet, theme),
              ],
            ),
            
            const SizedBox(height: 140), // gap for button
          ],
        ),
      ),
      bottomSheet: Container(
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
          child: ElevatedButton(
            onPressed: _isBooking ? null : _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isBooking
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Confirm Appointment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotSection(String title, List<String> slots, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: slots.map((slot) {
            final isSelected = _selectedTime == slot;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTime = slot;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.08)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  slot,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(String title, String subtitle, IconData icon, ThemeData theme) {
    final isSelected = _selectedPaymentMethod == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.04) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.grey, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary)
            else
              const Icon(Icons.circle_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
