import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checklist_item.dart';
import '../data/machine_checklists.dart';

class ChecklistProvider extends ChangeNotifier {
  List<ChecklistItem> _items = [];
  bool _isLoading = false;
  String _error = '';

  List<ChecklistItem> get items => [..._items];
  bool get isLoading => _isLoading;
  String get error => _error;

  ChecklistProvider() {
    _loadItems();
  }

  /// Loads saved checklist items from SharedPreferences
  Future<void> _loadItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = prefs.getStringList('checklist_items') ?? [];
      
      _items = itemsJson
          .map((itemJson) => ChecklistItem.fromJson(
              Map<String, dynamic>.from(
                  Map<String, dynamic>.from(
                      Uri.splitQueryString(itemJson).map((key, value) => MapEntry(key, value))))))
          .toList();
      
      _error = '';
    } catch (e) {
      _error = 'Error loading checklist items: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Saves checklist items to SharedPreferences
  Future<void> _saveItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = _items
          .map((item) => Uri(queryParameters: item.toJson()).query)
          .toList();
      
      await prefs.setStringList('checklist_items', itemsJson);
    } catch (e) {
      _error = 'Error saving checklist items: $e';
      print(_error);
    }
  }

  /// Adds a new checklist item
  Future<void> addChecklistItem(ChecklistItem item) async {
    _items.add(item);
    await _saveItems();
    notifyListeners();
  }

  /// Updates an existing checklist item
  Future<void> updateChecklistItem(ChecklistItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      await _saveItems();
      notifyListeners();
    }
  }

  /// Deletes a checklist item
  Future<void> deleteChecklistItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _saveItems();
    notifyListeners();
  }

  /// Gets checklist items for a specific equipment
  List<ChecklistItem> getChecklistItemsForEquipment(String equipmentId) {
    return _items.where((item) => item.equipmentId == equipmentId).toList();
  }

  /// Gets checklist items for a specific machine type, equipment, and frequency
  List<ChecklistItem> getMachineChecklistItems(String equipmentId, String machineType, ChecklistFrequency frequency) {
    return _items.where((item) => 
      item.equipmentId == equipmentId && 
      item.categoryName == machineType &&
      item.frequency == frequency
    ).toList();
  }

  /// Creates and saves checklist items for a machine type
  Future<void> createMachineChecklists(String equipmentId, String machineType) async {
    // Generate all checklist items for this machine type
    final items = MachineChecklists.initializeAllChecklistsForMachine(equipmentId, machineType);
    
    // Save the items
    for (var item in items) {
      await addChecklistItem(item);
    }
    
    notifyListeners();
  }
} 