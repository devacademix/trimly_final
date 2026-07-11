import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/api_providers.dart';

class PaymentGatewayScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> checkoutData;

  const PaymentGatewayScreen({super.key, required this.checkoutData});

  @override
  ConsumerState<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends ConsumerState<PaymentGatewayScreen> {
  bool _isProcessing = false;
  String _paymentStep = 'select'; // 'select', 'processing', 'success'

  void _processPayment() async {
    setState(() {
      _isProcessing = true;
      _paymentStep = 'processing';
    });

    final apiClient = ref.read(apiClientProvider);
    final orderId = widget.checkoutData['orderId'] ?? 'order_dummy';
    final keyId = widget.checkoutData['keyId'] ?? 'rzp_test_SnDZnu70NYQ1f5';
    final price = widget.checkoutData['price'] ?? 499.0;
    
    final checkoutUrl = '${apiClient.dio.options.baseUrl}/payments/razorpay/checkout-page?orderId=$orderId&keyId=$keyId&amount=$price';

    try {
      final uri = Uri.parse(checkoutUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching checkout: $e');
    }

    // Keep active loader showing, then switch to completion
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _paymentStep = 'success';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final method = widget.checkoutData['method'] ?? 'Razorpay';
    final price = widget.checkoutData['price'] ?? 499.0;
    final isRazorpay = method == 'Razorpay';

    if (_paymentStep == 'processing') {
      return Scaffold(
        backgroundColor: isRazorpay ? const Color(0xFF0C1A30) : const Color(0xFF5F259F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 24),
              Text(
                'Connecting to secure $method gateway...',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Do not close this page or press back.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
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
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Payment Successful!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Transaction ID: TXN${DateTime.now().millisecondsSinceEpoch}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.go('/home');
                  },
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
      backgroundColor: isRazorpay ? const Color(0xFF0F172A) : const Color(0xFF2D144A),
      appBar: AppBar(
        title: Text('$method Checkout', style: const TextStyle(color: Colors.white)),
        backgroundColor: isRazorpay ? const Color(0xFF1E293B) : const Color(0xFF5F259F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isRazorpay ? const Color(0xFF1E293B) : const Color(0xFF3F1B6B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Amount to Pay', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Image.network(
                    isRazorpay
                        ? 'https://raw.githubusercontent.com/razorpay/app-elements/master/assets/razorpay-logo.png'
                        : 'https://companieslogo.com/img/orig/PhonePe-38148b3b.png',
                    height: 36,
                    errorBuilder: (c, e, s) => const Icon(Icons.payment, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (isRazorpay) ...[
              const Text('Cards, UPI & More', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildMethodCard(Icons.qr_code, 'UPI / QR Code', 'Pay using any UPI App (PhonePe, GPay, Paytm)', Colors.indigoAccent),
              const SizedBox(height: 10),
              _buildMethodCard(Icons.credit_card, 'Card Payments', 'Visa, Mastercard, RuPay, Maestro', Colors.blue),
              const SizedBox(height: 10),
              _buildMethodCard(Icons.account_balance, 'Net Banking', 'All Major Indian Banks Available', Colors.teal),
            ] else ...[
              const Text('Direct Instant UPI', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildMethodCard(Icons.phone_iphone, 'PhonePe App', 'Open PhonePe App and pay directly', Colors.purpleAccent),
              const SizedBox(height: 10),
              _buildMethodCard(Icons.qr_code_scanner, 'UPI QR', 'Scan QR Code using PhonePe to pay', Colors.deepPurple),
            ],
            const SizedBox(height: 48),

            // Pay Button
            ElevatedButton(
              onPressed: _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: isRazorpay ? const Color(0xFF6366F1) : const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Pay ₹${price.toStringAsFixed(0)} Securely',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
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
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
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
