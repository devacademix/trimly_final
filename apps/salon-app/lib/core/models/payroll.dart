class StaffPayrollResult {
  final String staffId;
  final String name;
  final double baseSalary;
  final double commissionRate;
  final double totalServicesRevenue;
  final double commissionAmount;
  final double totalAmount;
  final String status; // 'PENDING' | 'PAID'
  final DateTime? paidAt;

  StaffPayrollResult({
    required this.staffId,
    required this.name,
    required this.baseSalary,
    required this.commissionRate,
    required this.totalServicesRevenue,
    required this.commissionAmount,
    required this.totalAmount,
    required this.status,
    this.paidAt,
  });

  factory StaffPayrollResult.fromJson(Map<String, dynamic> json) {
    return StaffPayrollResult(
      staffId: json['staffId'] as String,
      name: json['name'] as String,
      baseSalary: double.parse(json['baseSalary'].toString()),
      commissionRate: double.parse(json['commissionRate'].toString()),
      totalServicesRevenue: double.parse(json['totalServicesRevenue'].toString()),
      commissionAmount: double.parse(json['commissionAmount'].toString()),
      totalAmount: double.parse(json['totalAmount'].toString()),
      status: json['status'] as String,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
    );
  }
}
