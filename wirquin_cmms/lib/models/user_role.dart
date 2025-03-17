// User roles for the application
// Admin: Can add/edit equipment, add checklist items, etc.
// Operator: Can only perform checks and update status

enum UserRole {
  admin,
  operator,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.operator:
        return 'Operator';
    }
  }

  bool get canAddEquipment {
    return this == UserRole.admin;
  }

  bool get canEditEquipment {
    return this == UserRole.admin;
  }

  bool get canAddChecklistItems {
    return this == UserRole.admin;
  }
} 