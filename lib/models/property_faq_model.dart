import 'package:equatable/equatable.dart';

class PropertyFaqModel extends Equatable {
  static const String tableName = 'property_faqs';

  final String id;
  final String propertyId;
  final String question;
  final String answer;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PropertyFaqModel({
    required this.id,
    required this.propertyId,
    required this.question,
    required this.answer,
    this.displayOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  static PropertyFaqModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return PropertyFaqModel(
        id: json?.toString() ?? '',
        propertyId: '',
        question: '',
        answer: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return PropertyFaqModel(
      id: json['id']?.toString() ?? '',
      propertyId: json['property_id'] is Map
          ? json['property_id']['id']?.toString() ?? ''
          : json['property_id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      displayOrder:
          int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'question': question,
        'answer': answer,
        'display_order': displayOrder,
        'is_active': isActive,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  PropertyFaqModel copyWith({
    String? id,
    String? propertyId,
    String? question,
    String? answer,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyFaqModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, propertyId, question, answer, displayOrder, isActive, createdAt, updatedAt];
}
