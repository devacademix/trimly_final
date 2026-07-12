import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/booking_draft.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/api_providers.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final BookingDraft draft;

  const BookingScreen({super.key, required this.draft});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  bool _isBooking = false;
  bool _isLoadingSlots = false;
  String _selectedPaymentMethod = 'Razorpay';
  List<String> _slots = [];
  String? _slotsError;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _slotsError = null;
      _selectedTime = null;
    });
    try {
      final result = await ref.read(bookingRepositoryProvider).getAvailability(
            tenantId: widget.draft.tenantId,
            branchId: widget.draft.branchId,
            date: _selectedDate,
            staffId: widget.draft.staff?.id,
          );
      if (!mounted) return;
      setState(() {
        _slots = result.isOpen ? result.slots : [];
        _slotsError = result.isOpen ? null : (result.reason ?? 'Closed on this date');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _slotsError = e is ApiException ? e.message : 'Failed to load available slots');
    } finally {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  DateTime _combineDateAndSlot(DateTime date, String slot) {
    // Slots are "HH:MM - HH:MM"; take the start time.
    final startStr = slot.split(' - ').first.trim();
    final parts = startStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Future<void> _confirmBooking() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot.')),
      );
      return;
    }

    setState(() => _isBooking = true);

    final bookingRepo = ref.read(bookingRepositoryProvider);
    final startTime = _combineDateAndSlot(_selectedDate, _selectedTime!);

    try {
      final booking = await bookingRepo.createBooking(
        tenantId: widget.draft.tenantId,
        branchId: widget.draft.branchId,
        serviceId: widget.draft.service.id,
        staffId: widget.draft.staff?.id,
        startTime: startTime,
      );

      if (!mounted) return;
      setState(() => _isBooking = false);

      if (_selectedPaymentMethod == 'Wallet') {
        _showConfirmedDialog();
        return;
      }

      final checkout = await bookingRepo.checkout(tenantId: widget.draft.tenantId, bookingId: booking.id);
      if (!mounted) return;

      context.push('/payment-gateway', extra: CheckoutDraft(
        tenantId: widget.draft.tenantId,
        bookingId: booking.id,
        orderId: checkout.orderId,
        keyId: checkout.keyId,
        price: checkout.amount,
        salonName: widget.draft.salonName,
        serviceName: widget.draft.service.name,
        paymentMethod: _selectedPaymentMethod,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBooking = false);
      final message = e is ApiException ? e.message : 'Something went wrong. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showConfirmedDialog() {
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
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('Booking Confirmed!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Your slot at ${widget.draft.salonName} is booked for ${_selectedDate.day}/${_selectedDate.month} at $_selectedTime.',
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go to Home'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = widget.draft.service;
    final staff = widget.draft.staff;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Slot')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    radius: 24,
                    backgroundImage: staff?.profileImageUrl != null ? NetworkImage(staff!.profileImageUrl!) : null,
                    child: staff?.profileImageUrl == null ? const Icon(Icons.content_cut) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          staff != null ? 'Specialist: ${staff.fullName} • ${service.duration} min' : '${service.duration} min',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${service.price.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text('Select Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 85,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = _selectedDate.day == date.day && _selectedDate.month == date.month;
                  final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = date);
                      _loadSlots();
                    },
                    child: Container(
                      width: 65,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            weekdays[date.weekday % 7],
                            style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 12),
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

            const Text('Select Time Slot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_isLoadingSlots)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_slotsError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(_slotsError!, style: const TextStyle(color: Colors.grey)),
              )
            else if (_slots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No slots available on this date.', style: TextStyle(color: Colors.grey)),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _slots.map((slot) {
                  final isSelected = _selectedTime == slot;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTime = slot),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primary.withOpacity(0.08) : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300),
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
            const SizedBox(height: 28),

            const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Column(
              children: [
                _buildPaymentMethodTile('Razorpay', 'Pay securely via Cards, Netbanking, or UPI', Icons.payment, theme),
                const SizedBox(height: 8),
                _buildPaymentMethodTile('Wallet', 'Use Trimly Wallet balance', Icons.wallet, theme),
              ],
            ),
            const SizedBox(height: 140),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isBooking ? null : _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isBooking
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Confirm Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(String title, String subtitle, IconData icon, ThemeData theme) {
    final isSelected = _selectedPaymentMethod == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = title),
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
            if (isSelected) Icon(Icons.check_circle, color: theme.colorScheme.primary) else const Icon(Icons.circle_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
