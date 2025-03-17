import 'package:flutter/foundation.dart';

class OEEData {
  final DateTime date;
  final String? equipmentId;
  final double availability;
  final double performance;
  final double quality;
  final double oee;
  final String? notes;

  OEEData({
    required this.date,
    this.equipmentId,
    required this.availability,
    required this.performance,
    required this.quality,
    required this.oee,
    this.notes,
  });

  factory OEEData.fromMap(Map<String, dynamic> map) {
    final availability = (map['Availability'] as num?)?.toDouble() ?? 0.0;
    final performance = (map['Performance'] as num?)?.toDouble() ?? 0.0;
    final quality = (map['Quality'] as num?)?.toDouble() ?? 0.0;
    
    // Calculate OEE if not provided
    final providedOee = (map['OEE'] as num?)?.toDouble();
    final calculatedOee = availability * performance * quality / 10000; // Convert from percentages
    final oee = providedOee ?? calculatedOee;

    return OEEData(
      date: map['Date'] is DateTime ? map['Date'] : DateTime.tryParse(map['Date']?.toString() ?? '') ?? DateTime.now(),
      equipmentId: map['Equipment ID']?.toString(),
      availability: availability,
      performance: performance,
      quality: quality,
      oee: oee,
      notes: map['Notes']?.toString(),
    );
  }
}

class OEEDataProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<OEEData> _oeeDataList = [];
  
  // Sample OEE data for demonstration
  final Map<String, double> _oeeData = {
    'Extruder 1': 85.2,
    'Extruder 2': 78.9,
    'Injection Moulding 1': 91.5,
    'Injection Moulding 2': 82.7,
    'Packaging Line 1': 88.3,
    'Packaging Line 2': 76.8,
    'CNC Machine 1': 93.1,
    'CNC Machine 2': 81.4,
  };

  // Sample availability data
  final Map<String, double> _availabilityData = {
    'Extruder 1': 92.3,
    'Extruder 2': 85.7,
    'Injection Moulding 1': 94.1,
    'Injection Moulding 2': 89.2,
    'Packaging Line 1': 91.8,
    'Packaging Line 2': 83.5,
    'CNC Machine 1': 96.7,
    'CNC Machine 2': 88.9,
  };

  // Sample performance data
  final Map<String, double> _performanceData = {
    'Extruder 1': 87.6,
    'Extruder 2': 82.4,
    'Injection Moulding 1': 93.2,
    'Injection Moulding 2': 85.1,
    'Packaging Line 1': 89.7,
    'Packaging Line 2': 81.3,
    'CNC Machine 1': 95.3,
    'CNC Machine 2': 83.8,
  };

  // Sample quality data
  final Map<String, double> _qualityData = {
    'Extruder 1': 94.8,
    'Extruder 2': 89.5,
    'Injection Moulding 1': 97.2,
    'Injection Moulding 2': 91.7,
    'Packaging Line 1': 93.1,
    'Packaging Line 2': 88.6,
    'CNC Machine 1': 98.4,
    'CNC Machine 2': 92.3,
  };

  // Constructor - initialize sample data
  OEEDataProvider() {
    _initializeSampleData();
  }

  void _initializeSampleData() {
    _oeeDataList = _oeeData.entries.map((entry) {
      return OEEData(
        date: DateTime.now(),
        equipmentId: entry.key,
        availability: _availabilityData[entry.key] ?? 0.0,
        performance: _performanceData[entry.key] ?? 0.0,
        quality: _qualityData[entry.key] ?? 0.0,
        oee: entry.value,
      );
    }).toList();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<OEEData> get oeeData => _oeeDataList;
  Map<String, double> get oeeDataMap => _oeeData;
  Map<String, double> get availabilityData => _availabilityData;
  Map<String, double> get performanceData => _performanceData;
  Map<String, double> get qualityData => _qualityData;
  
  // Calculate overall OEE
  double calculateOverallOEE() {
    if (_oeeDataList.isEmpty) return 0.0;
    double sum = 0.0;
    for (var data in _oeeDataList) {
      sum += data.oee;
    }
    return sum / _oeeDataList.length;
  }
  
  // Get OEE for a specific machine
  double getOEE(String machineName) {
    return _oeeData[machineName] ?? 0.0;
  }
  
  // Get availability for a specific machine
  double getAvailability(String machineName) {
    return _availabilityData[machineName] ?? 0.0;
  }
  
  // Get performance for a specific machine
  double getPerformance(String machineName) {
    return _performanceData[machineName] ?? 0.0;
  }
  
  // Get quality for a specific machine
  double getQuality(String machineName) {
    return _qualityData[machineName] ?? 0.0;
  }
  
  // Update OEE data
  void updateOEE(String machineName, double value) {
    _oeeData[machineName] = value;
    _initializeSampleData(); // Regenerate OEE data list
    notifyListeners();
  }
  
  // Update availability data
  void updateAvailability(String machineName, double value) {
    _availabilityData[machineName] = value;
    _initializeSampleData(); // Regenerate OEE data list
    notifyListeners();
  }
  
  // Update performance data
  void updatePerformance(String machineName, double value) {
    _performanceData[machineName] = value;
    _initializeSampleData(); // Regenerate OEE data list
    notifyListeners();
  }
  
  // Update quality data
  void updateQuality(String machineName, double value) {
    _qualityData[machineName] = value;
    _initializeSampleData(); // Regenerate OEE data list
    notifyListeners();
  }
} 