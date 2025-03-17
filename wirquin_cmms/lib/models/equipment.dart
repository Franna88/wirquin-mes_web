class Equipment {
  final String id;
  final String name;
  final String location;
  final String department;
  final String manufacturer;
  final String model;
  final String serialNumber;
  final String installationDate;
  final String lastMaintenanceDate;
  final String status;
  final String machineType;

  Equipment({
    required this.id,
    required this.name,
    this.location = '',
    this.department = '',
    this.manufacturer = '',
    this.model = '',
    this.serialNumber = '',
    this.installationDate = '',
    this.lastMaintenanceDate = '',
    this.status = 'Operational',
    this.machineType = 'General',
  });

  // Create a copy of this Equipment with modified fields
  Equipment copyWith({
    String? id,
    String? name,
    String? location,
    String? department,
    String? manufacturer,
    String? model,
    String? serialNumber,
    String? installationDate,
    String? lastMaintenanceDate,
    String? status,
    String? machineType,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      department: department ?? this.department,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      installationDate: installationDate ?? this.installationDate,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      status: status ?? this.status,
      machineType: machineType ?? this.machineType,
    );
  }

  // Convert to and from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'department': department,
      'manufacturer': manufacturer,
      'model': model,
      'serialNumber': serialNumber,
      'installationDate': installationDate,
      'lastMaintenanceDate': lastMaintenanceDate,
      'status': status,
      'machineType': machineType,
    };
  }

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      department: json['department'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      model: json['model'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      installationDate: json['installationDate'] ?? '',
      lastMaintenanceDate: json['lastMaintenanceDate'] ?? '',
      status: json['status'] ?? 'Operational',
      machineType: json['machineType'] ?? 'General',
    );
  }
} 