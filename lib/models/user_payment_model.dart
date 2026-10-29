import 'package:equatable/equatable.dart';

import 'broker_model.dart';
import 'subscription_plan_model.dart';

class UserPaymentModel extends Equatable {
  static const String tableName = 'user_payments';

  final String id;
  final String brokerId;
  final String? subscriptionPlanId;
  final double amount;
  final String purpose;
  final String status;
  final String paymentProvider;
  final String? paymentId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final BrokerModel? broker;
  final SubscriptionPlanModel? plan;

  const UserPaymentModel({
    required this.id,
    required this.brokerId,
    this.subscriptionPlanId,
    required this.amount,
    required this.purpose,
    required this.status,
    required this.paymentProvider,
    this.paymentId,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.broker,
    this.plan,
  });

  bool get isPending => status == 'pending';
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';

  static UserPaymentModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return UserPaymentModel(
        id: json?.toString() ?? '',
        brokerId: '',
        amount: 0,
        purpose: 'buy_subscription',
        status: 'pending',
        paymentProvider: 'razorpay',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return UserPaymentModel(
      id: json['id']?.toString() ?? '',
      brokerId: json['broker_id'] is Map
          ? json['broker_id']['id']?.toString() ?? ''
          : json['broker_id']?.toString() ?? '',
      subscriptionPlanId: json['subscription_plan_id'] is Map
          ? json['subscription_plan_id']['id']?.toString()
          : json['subscription_plan_id']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      purpose: json['purpose']?.toString() ?? 'buy_subscription',
      status: json['status']?.toString() ?? 'pending',
      paymentProvider: json['payment_provider']?.toString() ?? 'razorpay',
      paymentId: json['payment_id']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      broker: json['broker_id'] is Map<String, dynamic>
          ? BrokerModel.fromJson(json['broker_id'])
          : null,
      plan: json['subscription_plan_id'] is Map<String, dynamic>
          ? SubscriptionPlanModel.fromJson(json['subscription_plan_id'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'broker_id': brokerId,
        if (subscriptionPlanId != null) 'subscription_plan_id': subscriptionPlanId,
        'amount': amount,
        'purpose': purpose,
        'status': status,
        'payment_provider': paymentProvider,
        if (paymentId != null) 'payment_id': paymentId,
        if (metadata != null) 'metadata': metadata,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  UserPaymentModel copyWith({
    String? id,
    String? brokerId,
    String? subscriptionPlanId,
    double? amount,
    String? purpose,
    String? status,
    String? paymentProvider,
    String? paymentId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    BrokerModel? broker,
    SubscriptionPlanModel? plan,
  }) {
    return UserPaymentModel(
      id: id ?? this.id,
      brokerId: brokerId ?? this.brokerId,
      subscriptionPlanId: subscriptionPlanId ?? this.subscriptionPlanId,
      amount: amount ?? this.amount,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      paymentId: paymentId ?? this.paymentId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      broker: broker ?? this.broker,
      plan: plan ?? this.plan,
    );
  }

  @override
  List<Object?> get props => [
        id,
        brokerId,
        subscriptionPlanId,
        amount,
        purpose,
        status,
        paymentProvider,
        paymentId,
        createdAt,
        updatedAt,
      ];
}
