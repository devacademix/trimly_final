/// Dashboard summary returned by GET /analytics/dashboard
class DashboardStats {
  final int todayBookingsCount;
  final int monthlyBookingsCount;
  final double totalVolume;
  final double salonRevenue;
  final double averageOrderValue;
  final int activeStaffCount;

  const DashboardStats({
    required this.todayBookingsCount,
    required this.monthlyBookingsCount,
    required this.totalVolume,
    required this.salonRevenue,
    required this.averageOrderValue,
    required this.activeStaffCount,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      todayBookingsCount: (json['todayBookingsCount'] as num?)?.toInt() ?? 0,
      monthlyBookingsCount: (json['monthlyBookingsCount'] as num?)?.toInt() ?? 0,
      totalVolume: (json['totalVolume'] as num?)?.toDouble() ?? 0.0,
      salonRevenue: (json['salonRevenue'] as num?)?.toDouble() ?? 0.0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      activeStaffCount: (json['activeStaffCount'] as num?)?.toInt() ?? 0,
    );
  }
}
