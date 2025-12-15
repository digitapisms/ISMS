import 'package:flutter/material.dart';

class InventoryItem {
  final String id;
  final String schoolId;
  final String? categoryId;
  final String itemCode;
  final String name;
  final String? description;
  final String unit;
  final double currentQuantity;
  final double minimumQuantity;
  final double? maximumQuantity;
  final double? unitPrice;
  final double? totalValue;
  final String? location;
  final String? supplierName;
  final String? supplierContact;
  final ConditionStatus conditionStatus;
  final bool isConsumable;
  final bool isActive;
  final DateTime? lastRestockedAt;
  final DateTime? lastUsedAt;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.schoolId,
    this.categoryId,
    required this.itemCode,
    required this.name,
    this.description,
    this.unit = 'piece',
    this.currentQuantity = 0,
    this.minimumQuantity = 0,
    this.maximumQuantity,
    this.unitPrice,
    this.totalValue,
    this.location,
    this.supplierName,
    this.supplierContact,
    this.conditionStatus = ConditionStatus.good,
    this.isConsumable = true,
    this.isActive = true,
    this.lastRestockedAt,
    this.lastUsedAt,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      categoryId: json['category_id'] as String?,
      itemCode: json['item_code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      unit: json['unit'] as String? ?? 'piece',
      currentQuantity: (json['current_quantity'] as num).toDouble(),
      minimumQuantity: (json['minimum_quantity'] as num?)?.toDouble() ?? 0,
      maximumQuantity: (json['maximum_quantity'] as num?)?.toDouble(),
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      totalValue: (json['total_value'] as num?)?.toDouble(),
      location: json['location'] as String?,
      supplierName: json['supplier_name'] as String?,
      supplierContact: json['supplier_contact'] as String?,
      conditionStatus: ConditionStatusX.fromDb(json['condition_status'] as String? ?? 'good'),
      isConsumable: json['is_consumable'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      lastRestockedAt: json['last_restocked_at'] != null
          ? DateTime.parse(json['last_restocked_at'] as String)
          : null,
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'category_id': categoryId,
      'item_code': itemCode,
      'name': name,
      'description': description,
      'unit': unit,
      'current_quantity': currentQuantity,
      'minimum_quantity': minimumQuantity,
      'maximum_quantity': maximumQuantity,
      'unit_price': unitPrice,
      'total_value': totalValue,
      'location': location,
      'supplier_name': supplierName,
      'supplier_contact': supplierContact,
      'condition_status': conditionStatus.dbValue,
      'is_consumable': isConsumable,
      'is_active': isActive,
      'last_restocked_at': lastRestockedAt?.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get needsRestock => currentQuantity <= minimumQuantity;
}

enum ConditionStatus {
  good,
  fair,
  poor,
  damaged,
}

extension ConditionStatusX on ConditionStatus {
  String get dbValue {
    switch (this) {
      case ConditionStatus.good:
        return 'good';
      case ConditionStatus.fair:
        return 'fair';
      case ConditionStatus.poor:
        return 'poor';
      case ConditionStatus.damaged:
        return 'damaged';
    }
  }

  String get displayName {
    switch (this) {
      case ConditionStatus.good:
        return 'Good';
      case ConditionStatus.fair:
        return 'Fair';
      case ConditionStatus.poor:
        return 'Poor';
      case ConditionStatus.damaged:
        return 'Damaged';
    }
  }

  Color get color {
    switch (this) {
      case ConditionStatus.good:
        return Colors.green;
      case ConditionStatus.fair:
        return Colors.orange;
      case ConditionStatus.poor:
        return Colors.red;
      case ConditionStatus.damaged:
        return Colors.red[900]!;
    }
  }

  static ConditionStatus fromDb(String value) {
    switch (value) {
      case 'good':
        return ConditionStatus.good;
      case 'fair':
        return ConditionStatus.fair;
      case 'poor':
        return ConditionStatus.poor;
      case 'damaged':
        return ConditionStatus.damaged;
      default:
        return ConditionStatus.good;
    }
  }
}
