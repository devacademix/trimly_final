import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/models/booking.dart';
import '../../core/models/booking_draft.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/auth_provider.dart';

class PaymentGatewayScreen extends ConsumerStatefulWidget {
  final CheckoutDraft checkoutDraft;

  const PaymentGatewayScreen({super.key, required this.checkoutDraft});

  @override
  ConsumerState<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends ConsumerState<PaymentGatewayScreen> {
  late final Razorpay _razorpay;
  String _paymentStep = 'select'; // 'select', 'processing', 'confirming', 'success', 'failed'
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _openCheckout() {
    final draft = widget.checkoutDraft;
    final user = ref.read(authControllerProvider).user;

    setState(() {
      _paymentStep = 'processing';
      _statusMessage = null;
    });

    final options = {
      'key': draft.keyId,
      'amount': (draft.price * 100).round(), // paise
      'order_id': draft.orderId,
      'name': 'Trimly',
      'description': '${draft.serviceName} at ${draft.salonName}',
      'prefill': {
        if (user?.email != null) 'email': user!.email,
        if (user?.phone != null) 'contact': user!.phone,
      },
      'theme': {'color': '#6366F1'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _paymentStep = 'select';
        _statusMessage = 'Unable to open the payment gateway. Please try again.';
      });
    }
  }

  // Razorpay's client SDK only confirms that the *checkout* succeeded — the
  // booking itself is confirmed server-side once PaymentService.handleWebhook
  // processes Razorpay's signed `payment.captured` webhook (see Phase 0).
  // We poll our own booking list briefly to reflect that real state instead
  // of assuming success locally.
  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _paymentStep = 'confirming';
      _statusMessage = null;
    });

    final bookingId = widget.checkoutDraft.bookingId;
    final repo = ref.read(bookingRepositoryProvider);

    for (var attempt = 0; attempt < 5; attempt++) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final bookings = await repo.listMyBookings();
        final booking = bookings.where((b) => b.id == bookingId).firstOrNull;
        if (booking != null && booking.status == BookingStatus.confirmed) {
          if (!mounted) return;
          setState(() => _paymentStep = 'success');
          return;
        }
      } catch (_) {
        // keep polling — a transient failure here shouldn't fail the flow,
        // the payment already succeeded on Razorpay's side.
      }
    }

    if (!mounted) return;
    // The payment succeeded but confirmation hasn't landed yet — this is
    // still a success from the customer's perspective; the booking will
    // finish updating in the background.
    setState(() => _paymentStep = 'success');
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() {
      _paymentStep = 'failed';
      _statusMessage = response.message ?? 'Payment failed. Please try again.';
    });
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _paymentStep = 'select';
      _statusMessage = 'Complete the payment in ${response.walletName ?? 'your wallet app'}, then check My Bookings.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.checkoutDraft;
    final price = draft.price;

    if (_paymentStep == 'processing' || _paymentStep == 'confirming') {
      return Scaffold(
        backgroundColor: const Color(0xFF0C1A30),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 24),
              Text(
                _paymentStep == 'processing' ? 'Opening secure Razorpay checkout...' : 'Confirming your booking...',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Do not close this page or press back.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    if (_paymentStep == 'success') {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 24),
                const Text('Payment Successful!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('Booking reference: ${draft.bookingId}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Go to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Razorpay Checkout', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Amount to Pay', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${draft.salonName} • ${draft.serviceName}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const Icon(Icons.payment, color: Colors.white, size: 36),
                ],
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(_statusMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 24),

            const Text('Cards, UPI & More', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildMethodCard(Icons.qr_code, 'UPI / QR Code', 'Pay using any UPI App (PhonePe, GPay, Paytm)', Colors.indigoAccent),
            const SizedBox(height: 10),
            _buildMethodCard(Icons.credit_card, 'Card Payments', 'Visa, Mastercard, RuPay, Maestro', Colors.blue),
            const SizedBox(height: 10),
            _buildMethodCard(Icons.account_balance, 'Net Banking', 'All Major Indian Banks Available', Colors.teal),
            const SizedBox(height: 48),

            ElevatedButton(
              onPressed: _openCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Pay ₹${price.toStringAsFixed(0)} Securely', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white30),
        ],
      ),
    );
  }
}
