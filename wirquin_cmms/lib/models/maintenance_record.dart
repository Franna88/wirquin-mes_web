class MaintenanceRecord {
  final String equipmentId;
  final String description;
  final String location;
  final String lastMaintenanceDate;
  final String nextMaintenanceDate;
  final String frequency;
  final String status;
  final String assignedTo;
  final String notes;

  MaintenanceRecord({
    required this.equipmentId,
    required this.description,
    required this.location,
    required this.lastMaintenanceDate,
    required this.nextMaintenanceDate,
    required this.frequency,
    required this.status,
    required this.assignedTo,
    required this.notes,
  });

  // Create from map (e.g., from Excel data)
  factory MaintenanceRecord.fromMap(Map<String, dynamic> map) {
    // Helper function to get string value with various possible keys
    String getStringValue(List<String> possibleKeys, {String defaultValue = ''}) {
      for (final key in possibleKeys) {
        if (map.containsKey(key) && map[key] != null) {
          return map[key].toString();
        }
      }
      return defaultValue;
    }

    return MaintenanceRecord(
      equipmentId: getStringValue(['Equipment ID', 'EquipmentID', 'ID', 'Asset Number']),
      description: getStringValue(['Description', 'Equipment Name', 'Name', 'Asset']),
      location: getStringValue(['Location', 'Area', 'Department']),
      lastMaintenanceDate: getStringValue(['Last Maintenance', 'Last Service Date', 'Last PM']),
      nextMaintenanceDate: getStringValue(['Next Maintenance', 'Next Service Date', 'Next PM']),
      frequency: getStringValue(['Frequency', 'Interval', 'Service Interval']),
      status: getStringValue(['Status', 'Condition', 'State']),
      assignedTo: getStringValue(['Assigned To', 'Responsible', 'Technician']),
      notes: getStringValue(['Notes', 'Comments', 'Additional Information']),
    );
  }

  // Create from row data (parsed from Excel)
  factory MaintenanceRecord.fromRowData(List<String> rowData, List<String> headers) {
    final map = <String, dynamic>{};
    for (var i = 0; i < headers.length && i < rowData.length; i++) {
      if (headers[i].isNotEmpty) {
        map[headers[i]] = rowData[i];
      }
    }
    return MaintenanceRecord.fromMap(map);
  }
} 