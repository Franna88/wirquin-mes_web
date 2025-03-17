import 'package:uuid/uuid.dart';

enum ChecklistFrequency {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly
}

extension ChecklistFrequencyExtension on ChecklistFrequency {
  String get displayName {
    switch (this) {
      case ChecklistFrequency.daily:
        return 'Daily';
      case ChecklistFrequency.weekly:
        return 'Weekly';
      case ChecklistFrequency.monthly:
        return 'Monthly';
      case ChecklistFrequency.quarterly:
        return 'Quarterly';
      case ChecklistFrequency.yearly:
        return 'Yearly';
    }
  }
}

class ChecklistItem {
  final String id;
  final String equipmentId;
  final String categoryName; // IM, BT, or TER
  final ChecklistFrequency frequency;
  final String description;
  String? notes;
  bool isCompleted;
  DateTime? lastCompletedDate;
  String result; // For storing YES, NO, GOOD, DONE, or numerical values
  String? photoUrl; // For storing the URL or path to a photo

  ChecklistItem({
    String? id,
    required this.equipmentId,
    required this.categoryName,
    required this.frequency,
    required this.description,
    this.notes,
    this.isCompleted = false,
    this.lastCompletedDate,
    this.result = '',
    this.photoUrl,
  }) : id = id ?? const Uuid().v4();

  ChecklistItem copyWith({
    String? id,
    String? equipmentId,
    String? categoryName,
    ChecklistFrequency? frequency,
    String? description,
    String? notes,
    bool? isCompleted,
    DateTime? lastCompletedDate,
    String? result,
    String? photoUrl,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      categoryName: categoryName ?? this.categoryName,
      frequency: frequency ?? this.frequency,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      result: result ?? this.result,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      'categoryName': categoryName,
      'frequency': frequency.toString().split('.').last,
      'description': description,
      'notes': notes,
      'isCompleted': isCompleted,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'result': result,
      'photoUrl': photoUrl,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      equipmentId: json['equipmentId'],
      categoryName: json['categoryName'],
      frequency: ChecklistFrequency.values.firstWhere(
        (e) => e.toString().split('.').last == json['frequency'],
      ),
      description: json['description'],
      notes: json['notes'],
      isCompleted: json['isCompleted'] ?? false,
      lastCompletedDate: json['lastCompletedDate'] != null 
          ? DateTime.parse(json['lastCompletedDate']) 
          : null,
      result: json['result'] ?? '',
      photoUrl: json['photoUrl'],
    );
  }
} 