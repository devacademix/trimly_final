class Coupon {
  final String id;
  final String code;
  final String discountType; // FLAT or PERCENTAGE
  final double value;
  final int? usageLimit;
  final int usedCount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  const Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.value,
    this.usageLimit,
    required this.usedCount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String,
      code: json['code'] as String,
      discountType: json['discountType'] as String,
      value: (json['value'] as num).toDouble(),
      usageLimit: json['usageLimit'] as int?,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class SalonReview {
  final String id;
  final String userId;
  final String customerName;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final List<ReviewReplyModel> replies;

  const SalonReview({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.replies,
  });

  factory SalonReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final repList = json['replies'] as List? ?? [];
    return SalonReview(
      id: json['id'] as String,
      userId: json['userId'] as String,
      customerName: user?['fullName'] as String? ?? 'Anonymous Customer',
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      replies: repList.map((x) => ReviewReplyModel.fromJson(x as Map<String, dynamic>)).toList(),
    );
  }
}

class ReviewReplyModel {
  final String id;
  final String replyText;
  final DateTime createdAt;

  const ReviewReplyModel({
    required this.id,
    required this.replyText,
    required this.createdAt,
  });

  factory ReviewReplyModel.fromJson(Map<String, dynamic> json) {
    return ReviewReplyModel(
      id: json['id'] as String,
      replyText: json['replyText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
