import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/data_providers.dart';

class AiAssistantScreen extends ConsumerWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiInsightsAsync = ref.watch(aiInsightsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('AI Business Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: aiInsightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Failed to generate AI insights: $err',
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (insights) {
          return SingleChildScrollView(
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
                  insights.peakHoursInsight,
                  insights.peakHoursSuggestion,
                  Icons.schedule,
                  Colors.orangeAccent,
                ),
                const SizedBox(height: 20),

                // Revenue Forecasting
                const Text('Revenue Forecast (Next Month)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildInsightCard(
                  insights.revenueInsight,
                  insights.revenueSuggestion,
                  Icons.trending_up,
                  Colors.green,
                ),
                const SizedBox(height: 20),

                // Suggested Price Changes
                const Text('Suggested Pricing Adjustments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildInsightCard(
                  insights.pricingInsight,
                  insights.pricingSuggestion,
                  Icons.monetization_on_outlined,
                  Colors.blueAccent,
                ),
                const SizedBox(height: 20),

                // Inventory Alerts
                const Text('Inventory Purchase Recommendation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildInsightCard(
                  insights.inventoryInsight,
                  insights.inventorySuggestion,
                  Icons.inventory,
                  Colors.redAccent,
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
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
          if (suggestion.isNotEmpty) ...[
            const Divider(color: Color(0xFF334155), height: 24),
            Text(
              suggestion,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
