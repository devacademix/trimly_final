class PeakHour {
  final int hour;
  final String label;
  final int count;

  const PeakHour({
    required this.hour,
    required this.label,
    required this.count,
  });

  factory PeakHour.fromJson(Map<String, dynamic> json) {
    return PeakHour(
      hour: json['hour'] as int,
      label: json['label'] as String,
      count: json['count'] as int,
    );
  }
}

class TopService {
  final String name;
  final int count;
  final double revenue;

  const TopService({
    required this.name,
    required this.count,
    required this.revenue,
  });

  factory TopService.fromJson(Map<String, dynamic> json) {
    return TopService(
      name: json['name'] as String,
      count: json['count'] as int,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}
