import 'checklist_item.dart';

enum MaintenanceCategoryType {
  inspectionMaintenance,  // IM - Inspection and Maintenance
  basicTasks,            // BT - Basic Tasks
  technicalEquipmentReview, // TER - Technical Equipment Review
}

extension MaintenanceCategoryTypeExtension on MaintenanceCategoryType {
  String get code {
    switch (this) {
      case MaintenanceCategoryType.inspectionMaintenance:
        return 'IM';
      case MaintenanceCategoryType.basicTasks:
        return 'BT';
      case MaintenanceCategoryType.technicalEquipmentReview:
        return 'TER';
    }
  }

  String get fullName {
    switch (this) {
      case MaintenanceCategoryType.inspectionMaintenance:
        return 'Inspection and Maintenance';
      case MaintenanceCategoryType.basicTasks:
        return 'Basic Tasks';
      case MaintenanceCategoryType.technicalEquipmentReview:
        return 'Technical Equipment Review';
    }
  }
}

class MaintenanceCategory {
  final String id;
  final String equipmentId;
  final MaintenanceCategoryType type;
  final Map<ChecklistFrequency, List<ChecklistItem>> checklists;
  
  MaintenanceCategory({
    required this.id,
    required this.equipmentId,
    required this.type,
    Map<ChecklistFrequency, List<ChecklistItem>>? checklists,
  }) : checklists = checklists ?? {};
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    final checklistsJson = <String, List<Map<String, dynamic>>>{};
    
    checklists.forEach((frequency, items) {
      checklistsJson[frequency.toString()] = items.map((item) => item.toJson()).toList();
    });
    
    return {
      'id': id,
      'equipmentId': equipmentId,
      'type': type.toString(),
      'checklists': checklistsJson,
    };
  }
  
  // Create from JSON
  factory MaintenanceCategory.fromJson(Map<String, dynamic> json) {
    final type = MaintenanceCategoryType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => MaintenanceCategoryType.inspectionMaintenance,
    );
    
    final checklistsJson = json['checklists'] as Map<String, dynamic>? ?? {};
    final checklists = <ChecklistFrequency, List<ChecklistItem>>{};
    
    checklistsJson.forEach((key, value) {
      final frequency = ChecklistFrequency.values.firstWhere(
        (e) => e.toString() == key,
        orElse: () => ChecklistFrequency.daily,
      );
      
      final items = (value as List).map((itemJson) => 
        ChecklistItem.fromJson(itemJson as Map<String, dynamic>)
      ).toList();
      
      checklists[frequency] = items;
    });
    
    return MaintenanceCategory(
      id: json['id'] ?? '',
      equipmentId: json['equipmentId'] ?? '',
      type: type,
      checklists: checklists,
    );
  }
} 