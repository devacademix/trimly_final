class CouponValidation {
  final bool isValid;
  final String? code;
  final String? discountType;
  final double discountAmount;
  final double finalAmount;
  final String? message;

  const CouponValidation({
    required this.isValid,
    this.code,
    this.discountType,
    required this.discountAmount,
    required this.finalAmount,
    this.message,
  });

  factory CouponValidation.fromJson(Map<String, dynamic> json) {
    return CouponValidation(
      isValid: json['isValid'] as bool? ?? false,
      code: json['code'] as String?,
      discountType: json['discountType'] as String?,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String?,
    );
  }
}

class SalonReview {
  final String id;
  final String customerName;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final List<ReviewReplyModel> replies;

  const SalonReview({
    required this.id,
    required this.customerName,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.replies,
  });

  factory SalonReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final reps = json['replies'] as List? ?? [];
    return SalonReview(
      id: json['id'] as String,
      customerName: user?['fullName'] as String? ?? 'Anonymous Customer',
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      replies: reps.map((x) => ReviewReplyModel.fromJson(x as Map<String, dynamic>)).toList(),
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
