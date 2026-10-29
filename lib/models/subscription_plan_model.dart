import 'package:equatable/equatable.dart';

class SubscriptionPlanModel extends Equatable {
  static const String tableName = 'subscription_plans';

  final String id;
  final String title;
  final double amount;
  final String description;
  final List<String> benefits;
  final bool isActive;
  final bool isPopular;
  final String? paymentProvider;
  final String billingType;
  final List<Map<String, dynamic>> durationOptions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionPlanModel({
    required this.id,
    required this.title,
    required this.amount,
    this.description = '',
    this.benefits = const [],
    this.isActive = true,
    this.isPopular = false,
    this.paymentProvider,
    required this.billingType,
    this.durationOptions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  static SubscriptionPlanModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return SubscriptionPlanModel(
        id: json?.toString() ?? '',
        title: '',
        amount: 0,
        billingType: 'monthly',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    List<String> parsedBenefits = [];
    if (json['benefits'] != null && json['benefits'] is List) {
      parsedBenefits =
          (json['benefits'] as List).map((e) => e.toString()).toList();
    }

    List<Map<String, dynamic>> parsedDurationOptions = [];
    if (json['duration_options'] != null && json['duration_options'] is List) {
      parsedDurationOptions = (json['duration_options'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return SubscriptionPlanModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      amount:
          double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString() ?? '',
      benefits: parsedBenefits,
      isActive: json['is_active'] as bool? ?? true,
      isPopular: json['is_popular'] as bool? ?? false,
      paymentProvider: json['payment_provider']?.toString(),
      billingType: json['billing_type']?.toString() ?? 'monthly',
      durationOptions: parsedDurationOptions,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'description': description,
        'benefits': benefits,
        'is_active': isActive,
        'is_popular': isPopular,
        if (paymentProvider != null) 'payment_provider': paymentProvider,
        'billing_type': billingType,
        'duration_options': durationOptions,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  SubscriptionPlanModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? description,
    List<String>? benefits,
    bool? isActive,
    bool? isPopular,
    String? paymentProvider,
    String? billingType,
    List<Map<String, dynamic>>? durationOptions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPlanModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      benefits: benefits ?? this.benefits,
      isActive: isActive ?? this.isActive,
      isPopular: isPopular ?? this.isPopular,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      billingType: billingType ?? this.billingType,
      durationOptions: durationOptions ?? this.durationOptions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        description,
        benefits,
        isActive,
        isPopular,
        paymentProvider,
        billingType,
        durationOptions,
        createdAt,
        updatedAt,
      ];
}
