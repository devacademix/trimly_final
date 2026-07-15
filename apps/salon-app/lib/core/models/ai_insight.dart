class AiInsights {
  final String peakHoursInsight;
  final String peakHoursSuggestion;
  final String revenueInsight;
  final String revenueSuggestion;
  final String pricingInsight;
  final String pricingSuggestion;
  final String inventoryInsight;
  final String inventorySuggestion;

  AiInsights({
    required this.peakHoursInsight,
    required this.peakHoursSuggestion,
    required this.revenueInsight,
    required this.revenueSuggestion,
    required this.pricingInsight,
    required this.pricingSuggestion,
    required this.inventoryInsight,
    required this.inventorySuggestion,
  });

  factory AiInsights.fromJson(Map<String, dynamic> json) {
    return AiInsights(
      peakHoursInsight: json['peakHoursInsight'] as String? ?? 'No peak hours data available.',
      peakHoursSuggestion: json['peakHoursSuggestion'] as String? ?? '',
      revenueInsight: json['revenueInsight'] as String? ?? 'No revenue forecast data available.',
      revenueSuggestion: json['revenueSuggestion'] as String? ?? '',
      pricingInsight: json['pricingInsight'] as String? ?? 'Service pricing is currently optimized.',
      pricingSuggestion: json['pricingSuggestion'] as String? ?? '',
      inventoryInsight: json['inventoryInsight'] as String? ?? 'No inventory alerts.',
      inventorySuggestion: json['inventorySuggestion'] as String? ?? '',
    );
  }
}
