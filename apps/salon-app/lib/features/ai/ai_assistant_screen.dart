import 'package:flutter/material.dart';

class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('AI Business Assistant', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Promo card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI insights are updated automatically based on your bookings history, peak hours, and staff performance.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Peak Hours Prediction card
            const Text('Peak Booking Hours Forecast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildInsightCard(
              'Saturday afternoons (1:00 PM - 4:00 PM) are projected to have 95% occupancy.',
              'Recommendation: Offer a 10% discount on Tuesday/Wednesday mornings to distribute traffic.',
              Icons.schedule,
              Colors.orangeAccent,
            ),
            const SizedBox(height: 20),

            // Revenue Forecasting
            const Text('Revenue Forecast (Next Month)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildInsightCard(
              'Expected Revenue: ₹2,10,000 (an increase of 14% compared to this month).',
              'Contributing Factors: High bridal season booking volumes starting next week.',
              Icons.trending_up,
              Colors.green,
            ),
            const SizedBox(height: 20),

            // Suggested Price Changes
            const Text('Suggested Pricing Adjustments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildInsightCard(
              'Gel Manicure prices can be safely raised by 10% due to consistent 100% specialist occupancy.',
              'Effect: Raise price from ₹799 to ₹879. Estimated monthly revenue impact: +₹4,500.',
              Icons.monetization_on_outlined,
              Colors.blueAccent,
            ),
            const SizedBox(height: 20),

            // Inventory Alerts
            const Text('Inventory Purchase Recommendation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildInsightCard(
              'Organic Shampoo stocks are projected to run out in 6 days based on current usage frequency.',
              'Action: Order 12 units from vendor Grooming Supplies Ltd immediately.',
              Icons.inventory,
              Colors.redAccent,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(String insight, String suggestion, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  insight,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 24),
          Text(
            suggestion,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
