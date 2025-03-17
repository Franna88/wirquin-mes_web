import 'package:flutter/foundation.dart';
import '../utils/excel_parser.dart';

class MaintenanceData {
  final String? equipmentId;
  final String? description;
  final String? location;
  final String? status;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;
  final String? maintenanceType;
  final String? responsiblePerson;
  final String? notes;

  MaintenanceData({
    this.equipmentId,
    this.description,
    this.location,
    this.status,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    this.maintenanceType,
    this.responsiblePerson,
    this.notes,
  });

  factory MaintenanceData.fromMap(Map<String, dynamic> map) {
    // Try to get values using both camelCase and Title Case keys
    String? getStringValue(List<String> possibleKeys) {
      for (final key in possibleKeys) {
        if (map.containsKey(key) && map[key] != null) {
          return map[key].toString();
        }
      }
      return null;
    }

    DateTime? getDateValue(List<String> possibleKeys) {
      for (final key in possibleKeys) {
        if (map.containsKey(key)) {
          if (map[key] is DateTime) {
            return map[key];
          } else if (map[key] != null) {
            return DateTime.tryParse(map[key].toString());
          }
        }
      }
      return null;
    }

    return MaintenanceData(
      equipmentId: getStringValue(['Equipment ID', 'EquipmentID', 'equipmentId', 'Machine ID', 'Asset ID']),
      description: getStringValue(['Description', 'description', 'Name', 'Equipment Name']),
      location: getStringValue(['Location', 'location', 'Area', 'Zone']),
      status: getStringValue(['Status', 'status', 'State', 'Condition']),
      lastMaintenanceDate: getDateValue(['Last Maintenance Date', 'LastMaintenanceDate', 'lastMaintenanceDate', 'Previous Maintenance']),
      nextMaintenanceDate: getDateValue(['Next Maintenance Date', 'NextMaintenanceDate', 'nextMaintenanceDate', 'Scheduled Maintenance']),
      maintenanceType: getStringValue(['Maintenance Type', 'MaintenanceType', 'maintenanceType', 'Type']),
      responsiblePerson: getStringValue(['Responsible', 'responsible', 'Technician', 'Assigned To']),
      notes: getStringValue(['Notes', 'notes', 'Comments', 'Details']),
    );
  }
}

class MaintenanceDataProvider extends ChangeNotifier {
  final List<MaintenanceData> _maintenanceItems = [];
  final ExcelParser _excelParser = ExcelParser();
  bool _isLoading = false;
  String? _error;

  List<MaintenanceData> get maintenanceItems => _maintenanceItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMaintenanceData(dynamic input) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rawData = await _excelParser.extractMaintenanceData(input);
      await loadMaintenanceDataFromMap(rawData);
    } catch (e) {
      _error = 'Failed to load maintenance data: $e';
      print(_error);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMaintenanceDataFromMap(List<Map<String, dynamic>> data) async {
    try {
      _maintenanceItems.clear();
      
      for (var item in data) {
        try {
          final maintenanceData = MaintenanceData.fromMap(item);
          // Only add items that have at least some basic data
          if (maintenanceData.equipmentId != null || 
              maintenanceData.description != null ||
              maintenanceData.location != null) {
            _maintenanceItems.add(maintenanceData);
          }
        } catch (e) {
          print('Error parsing maintenance item: $e');
        }
      }
      
      print('Imported ${_maintenanceItems.length} maintenance items');
    } catch (e) {
      _error = 'Failed to process maintenance data: $e';
      print(_error);
    }
  }

  // Add maintenance item
  void addMaintenanceItem(MaintenanceData item) {
    _maintenanceItems.add(item);
    notifyListeners();
  }

  // Update maintenance item
  void updateMaintenanceItem(int index, MaintenanceData item) {
    if (index >= 0 && index < _maintenanceItems.length) {
      _maintenanceItems[index] = item;
      notifyListeners();
    }
  }

  // Delete maintenance item
  void deleteMaintenanceItem(int index) {
    if (index >= 0 && index < _maintenanceItems.length) {
      _maintenanceItems.removeAt(index);
      notifyListeners();
    }
  }
} 