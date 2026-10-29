import 'package:equatable/equatable.dart';

import 'broker_model.dart';
import 'subscription_plan_model.dart';

class UserSubscriptionModel extends Equatable {
  static const String tableName = 'user_subscriptions';

  final String id;
  final String brokerId;
  final String paymentId;
  final String subscriptionPlanId;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final double amount;
  final String planCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final BrokerModel? broker;
  final SubscriptionPlanModel? plan;

  const UserSubscriptionModel({
    required this.id,
    required this.brokerId,
    required this.paymentId,
    required this.subscriptionPlanId,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.amount,
    required this.planCode,
    required this.createdAt,
    required this.updatedAt,
    this.broker,
    this.plan,
  });

  bool get isActive => DateTime.now().isBefore(endDate);

  int get daysRemaining {
    final remaining = endDate.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  static UserSubscriptionModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return UserSubscriptionModel(
        id: json?.toString() ?? '',
        brokerId: '',
        paymentId: '',
        subscriptionPlanId: '',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        totalDays: 0,
        amount: 0,
        planCode: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return UserSubscriptionModel(
      id: json['id']?.toString() ?? '',
      brokerId: json['broker_id'] is Map
          ? json['broker_id']['id']?.toString() ?? ''
          : json['broker_id']?.toString() ?? '',
      paymentId: json['payment_id']?.toString() ?? '',
      subscriptionPlanId: json['subscription_plan_id'] is Map
          ? json['subscription_plan_id']['id']?.toString() ?? ''
          : json['subscription_plan_id']?.toString() ?? '',
      startDate:
          DateTime.tryParse(json['start_date']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      endDate:
          DateTime.tryParse(json['end_date']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      totalDays: int.tryParse(json['total_days']?.toString() ?? '0') ?? 0,
      amount:
          double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      planCode: json['plan_code']?.toString() ?? '',
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
        'payment_id': paymentId,
        'subscription_plan_id': subscriptionPlanId,
        'start_date': startDate.toUtc().toIso8601String(),
        'end_date': endDate.toUtc().toIso8601String(),
        'total_days': totalDays,
        'amount': amount,
        'plan_code': planCode,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  UserSubscriptionModel copyWith({
    String? id,
    String? brokerId,
    String? paymentId,
    String? subscriptionPlanId,
    DateTime? startDate,
    DateTime? endDate,
    int? totalDays,
    double? amount,
    String? planCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    BrokerModel? broker,
    SubscriptionPlanModel? plan,
  }) {
    return UserSubscriptionModel(
      id: id ?? this.id,
      brokerId: brokerId ?? this.brokerId,
      paymentId: paymentId ?? this.paymentId,
      subscriptionPlanId: subscriptionPlanId ?? this.subscriptionPlanId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      amount: amount ?? this.amount,
      planCode: planCode ?? this.planCode,
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
        paymentId,
        subscriptionPlanId,
        startDate,
        endDate,
        totalDays,
        amount,
        planCode,
        createdAt,
        updatedAt,
      ];
}
