import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checklist_item.dart';
import '../providers/equipment_provider.dart';
import '../models/maintenance_category.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../data/machine_checklists.dart';

class ChecklistProvider extends ChangeNotifier {
  Map<String, List<ChecklistItem>> _checklistItems = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  ChecklistProvider() {
    _init();
  }
  
  // Returns all keys in the _checklistItems map
  List<String> getAllKeys() {
    return _checklistItems.keys.toList();
  }
  
  // Returns all checklist items across all categories and equipment
  List<ChecklistItem> getAllItems() {
    return _checklistItems.values.expand((items) => items).toList();
  }
  
  Future<void> _init() async {
    // Load items from shared preferences first
    await _loadItems();
    
    // Schedule a delayed load of any missing checklist items 
    // from the equipment provider
    Future.delayed(const Duration(seconds: 3), () {
      _extractChecklistsFromEquipment();
    });
  }

  Future<void> _loadItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = prefs.getString('checklist_items');
      
      if (itemsJson != null) {
        final Map<String, dynamic> decodedData = jsonDecode(itemsJson);
        
        _checklistItems = {};
        decodedData.forEach((key, value) {
          final List<dynamic> itemsList = value;
          _checklistItems[key] = itemsList
              .map((item) => ChecklistItem.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading checklist items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final Map<String, List<Map<String, dynamic>>> serializedItems = {};
      _checklistItems.forEach((key, items) {
        serializedItems[key] = items.map((item) => item.toJson()).toList();
      });
      
      final String itemsJson = jsonEncode(serializedItems);
      await prefs.setString('checklist_items', itemsJson);
    } catch (e) {
      debugPrint('Error saving checklist items: $e');
    }
  }

  List<ChecklistItem> getItems(String key) {
    return _checklistItems[key] ?? [];
  }

  List<ChecklistItem> getItemsForCategoryAndFrequency(
    String equipmentId,
    String categoryCode,
    ChecklistFrequency frequency,
  ) {
    final key = '$equipmentId|$categoryCode|${frequency.toString()}';
    return getItems(key);
  }

  Future<void> updateItem(ChecklistItem item) async {
    final key = '${item.equipmentId}|${item.categoryName}|${item.frequency.toString()}';
    
    if (!_checklistItems.containsKey(key)) {
      _checklistItems[key] = [];
    }
    
    final index = _checklistItems[key]!.indexWhere((i) => i.id == item.id);
    
    if (index >= 0) {
      _checklistItems[key]![index] = item;
    } else {
      _checklistItems[key]!.add(item);
    }
    
    await _saveItems();
    notifyListeners();
  }

  Future<void> deleteItem(dynamic item) async {
    // Handle both ChecklistItem objects and string IDs
    String? itemId;
    String? key;
    
    if (item is ChecklistItem) {
      itemId = item.id;
      key = '${item.equipmentId}|${item.categoryName}|${item.frequency.toString()}';
    } else if (item is String) {
      itemId = item;
      // We need to search through all keys
      key = null;
    }
    
    if (itemId == null) return;
    
    if (key != null) {
      // We know the exact key
      if (_checklistItems.containsKey(key)) {
        _checklistItems[key]!.removeWhere((i) => i.id == itemId);
        await _saveItems();
        notifyListeners();
      }
    } else {
      // We need to search through all items
      var itemFound = false;
      
      for (var entry in _checklistItems.entries) {
        final itemIndex = entry.value.indexWhere((i) => i.id == itemId);
        if (itemIndex >= 0) {
          entry.value.removeAt(itemIndex);
          itemFound = true;
        }
      }
      
      if (itemFound) {
        await _saveItems();
        notifyListeners();
      }
    }
  }

  List<ChecklistItem> getItemsForEquipment(String equipmentId) {
    return _checklistItems.values.expand((items) => items).where((item) => item.equipmentId == equipmentId).toList();
  }

  // Alias for getItemsForEquipment
  List<ChecklistItem> getChecklistItemsForEquipment(String equipmentId) {
    return getItemsForEquipment(equipmentId);
  }

  List<ChecklistItem> getItemsForCategory(String equipmentId, String categoryName) {
    return _checklistItems.values.expand((items) => items).where((item) => 
      item.equipmentId == equipmentId && 
      item.categoryName == categoryName
    ).toList();
  }

  Future<void> addItem(ChecklistItem item) async {
    final key = '${item.equipmentId}|${item.categoryName}|${item.frequency.toString()}';
    
    if (!_checklistItems.containsKey(key)) {
      _checklistItems[key] = [];
    }
    
    // Check if item already exists
    final existingIndex = _checklistItems[key]!.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      _checklistItems[key]![existingIndex] = item;
    } else {
      _checklistItems[key]!.add(item);
    }
    
    await _saveItems();
    notifyListeners();
  }

  Future<void> toggleItemCompletion(String id, bool isCompleted) async {
    for (var items in _checklistItems.values) {
      final index = items.indexWhere((item) => item.id == id);
      if (index != -1) {
        final item = items[index];
        final updatedItem = item.copyWith(
          isCompleted: isCompleted,
          lastCompletedDate: isCompleted ? DateTime.now() : null,
        );
        items[index] = updatedItem;
        await _saveItems();
        notifyListeners();
      }
    }
  }

  Future<void> addDefaultChecklistItems(String equipmentId) async {
    // IM (Injection Molding) Daily Checklist Items
    final imDailyItems = [
      'Test E/STOP function',
      'Grease mold pillars',
      'Door stop functions in MAN (TESTED)',
      'Door stop functions in SEMI (TESTED)',
      'Door stop functions in AUTO (TESTED)',
      'Is the mechanical safety secure',
      'Are the mold clamps secure',
      'Are there any water leaks',
      'Are there any HYD oil leaks',
      'Are all the guards in place and secure',
      'Housekeeping of area and machine',
      'Actual HYD oil temp on screen',
      'Actual HYD oil temp on thermometer',
      'HYD oil set point',
      'HYD oil [+ve] over set point',
      'HYD oil [-ve] under set point',
      'Does the thermocouples and heaters work',
      'Is the lube oil level correct',
      'Is the HYD oil level correct',
      'Is there water flow on the barrel',
    ];

    // IM Weekly Checklist Items
    final imWeeklyItems = [
      'Check lube lines for any damages',
      'Clean water strainer on the main line',
      'Does the guard doors still close easily',
      'Grease thrust bearings and slides',
    ];

    // IM Monthly Checklist Items
    final imMonthlyItems = [
      'Test E/STOP function',
      'Door stop functions in MAN (TESTED)',
      'Door stop functions in SEMI (TESTED)',
      'Door stop functions in AUTO (TESTED)',
      'Is the mechanical safety secure',
      'Are the mold clamps secure',
      'Are there any water leaks',
      'Are there any HYD oil leaks',
      'Are all the guards in place and secure',
      'Housekeeping of area and machine',
      'Actual HYD oil temp on screen',
      'Actual HYD oil temp on thermometer',
      'HYD oil set point',
      'HYD oil [+ve] over set point',
      'HYD oil [-ve] under set point',
      'Does the thermocouples and heaters work',
      'Is the lube oil level correct',
      'Is the HYD oil level correct',
      'Check lube lines for any damages',
      'Does the guard doors still close easily',
      'Check for loose wiring',
      'Control on working pressure',
      'Does the pressure gauge work',
      'Grease thrust bearings and slides',
      'Clean panel fan filters',
      'Does all the panel fans work',
      'Oil sample for yearly required',
      'Clean water strainer',
    ];

    // IM Quarterly Checklist Items
    final imQuarterlyItems = [
      'Test E/STOP function',
      'Door stop functions in MAN (TESTED)',
      'Door stop functions in SEMI (TESTED)',
      'Door stop functions in AUTO (TESTED)',
      'Is the mechanical safety secure',
      'Are the mold clamps secure',
      'Are there any water leaks',
      'Are there any HYD oil leaks',
      'Are all the guards in place and secure',
      'Housekeeping of area and machine',
      'Actual HYD oil temp on screen',
      'Actual HYD oil temp on thermometer',
      'HYD oil set point',
      'HYD oil [+ve] over set point',
      'HYD oil [-ve] under set point',
      'Does the thermocouples and heaters work',
      'Is the lube oil level correct',
      'Is the HYD oil level correct',
      'Check lube lines for any damages',
      'Does the guard doors still close easily',
      'Check for loose connections in panel',
      'Control on working pressure',
      'Does the pressure gauge work',
      'Is the heaters and thermocouples secure',
      'Check all the proxies are switching',
      'Ensure nozzle alignment',
      'Grease thrust bearings and slides',
      'Check field wiring',
      'Check contactors and relays',
      'Check tie bar nuts secure',
      'Check machine level in spec',
      'Check and clean cooler',
      'Clean panel fan filters',
      'Does all the panel fans work',
      'Clean water strainer',
    ];

    // IM 6-Monthly Checklist Items (added to Yearly)
    final imSixMonthlyItems = [
      'Drain HYD oil and clean tank',
      'Was the HYD oil reused',
    ];

    // IM Yearly Checklist Items
    final imYearlyItems = [
      'Replace filter media of panel fans',
      'Check and clean oil cooler',
      'Check water flow on platens',
      'Check for oil leaks on main ram',
      'Check for bearing noise',
      'Clean suction strainer/replace if required',
    ];

    // BT (Bettatec) Daily Checklist Items
    final btDailyItems = [
      'Test E/STOP function on machine',
      'Test E/STOP function on saw',
      'Test two-hand operation (TESTED)',
      'Test two-hand operation on saw (TESTED)',
      'Are the mold clamps secure',
      'Are there any water leaks',
      'Are there any HYD oil leaks',
      'Is the mold heater water level correct',
      'Is the HYD oil level correct',
      'Does the thermocouples and heaters work',
      'Saw guard is operational',
      'Saw clamps operational',
      'Does the door safeties work',
      'Are all the guards in place and secure',
      'Actual HYD oil temp on thermometer',
      'Housekeeping of area and machine',
    ];

    // BT Weekly Checklist Items
    final btWeeklyItems = [
      'Check for air leaks',
      'Clean mold surface',
    ];

    // BT Monthly Checklist Items
    final btMonthlyItems = [
      'Check for loose wiring',
      'Check saw v-belt',
      'Grease and oil slides',
      'Check granulator blades',
      'Check for loose bolts on granulator',
      'Check saw blade for wear',
      'Check and clean oil cooler',
      'Check granulator gear oil',
      'Check field wiring',
      'Check all proxies are switching and secure',
      'Check contactors and relays',
      'Check for loose connections',
      'Check gripper and nozzle alignment',
      'Check tie bar nuts secure',
      'Drain HYD oil and clean tank',
      'Was the HYD oil reused',
      'Clean suction strainer/replace if required',
      'Clean motor cooling fans',
    ];

    // BT Quarterly Checklist Items
    final btQuarterlyItems = [
      'Oil sample for yearly required',
    ];

    // BT 6-Monthly and Yearly Checklist Items are included in notes

    // TER (Terrestrial) Daily Checklist Items
    final terDailyItems = [
      'Check mold hoses not shaving',
      'Check mold hoses not leaking on coupling',
      'Check mold clamps secure',
      'Are there any water leaks',
      'Are there any HYD oil leaks',
      'Door open motor stop functional LH/RH',
      'Are all the guards in place and secure',
      'HYD oil temp on screen LH/RH',
      'Is the HYD oil level correct LH/RH',
      'Grease mold pillars LH & RH',
      'Clean pillar holes LH & RH',
      'Test all E/STOPs',
      'Test safety curtain',
      'Are the platens warm to touch',
      'Clean all flash from platens',
      'Clean and weigh material dumped',
    ];

    // TER Weekly Checklist Items
    final terWeeklyItems = [
      'Clean all panel filters',
      'Clean water strainer on main line',
      'Check shutter bolts secure',
      'Does the doors still open/close easily',
      'Check whisker protector secure',
    ];

    // TER Monthly Checklist Items
    final terMonthlyItems = [
      'Check for air leaks',
      'Grease loader/unloader slides',
      'Check island interlock',
      'Check indication globes/replace',
      'Check for loose connections in panels',
      'Control on working pressure',
      'Does the pressure gauge work',
      'Ensure ejector head and ext. secure',
    ];

    // TER Quarterly Checklist Items
    final terQuarterlyItems = [
      'Take oil sample',
    ];

    // TER 6-Monthly Checklist Items
    final terSixMonthlyItems = [
      'Replace filter media of panel fans',
      'Check and clean oil cooler',
      'Check water flow on platens',
      'Check for oil leaks on main ram',
      'Check for bearing noise',
    ];

    // TER Yearly Checklist Items
    final terYearlyItems = [
      'Disconnect/reconnect all thermocouple wiring',
      'Open and clean water ports',
      'Check ejector sensors secure',
    ];

    // Add IM daily items
    for (final description in imDailyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'IM',
        frequency: ChecklistFrequency.daily,
        description: description,
      ));
    }

    // Add IM weekly items
    for (final description in imWeeklyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'IM',
        frequency: ChecklistFrequency.weekly,
        description: description,
      ));
    }

    // Add IM monthly items
    for (final description in imMonthlyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'IM',
        frequency: ChecklistFrequency.monthly,
        description: description,
      ));
    }

    // Add IM quarterly items
    for (final description in imQuarterlyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'IM',
        frequency: ChecklistFrequency.quarterly,
        description: description,
      ));
    }

    // Add IM yearly items (including 6-monthly items)
    for (final description in [...imSixMonthlyItems, ...imYearlyItems]) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'IM',
        frequency: ChecklistFrequency.yearly,
        description: description,
      ));
    }

    // Add BT daily items
    for (final description in btDailyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'BT',
        frequency: ChecklistFrequency.daily,
        description: description,
      ));
    }

    // Add BT weekly items
    for (final description in btWeeklyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'BT',
        frequency: ChecklistFrequency.weekly,
        description: description,
      ));
    }

    // Add BT monthly items
    for (final description in btMonthlyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'BT',
        frequency: ChecklistFrequency.monthly,
        description: description,
      ));
    }

    // Add BT quarterly items
    for (final description in btQuarterlyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'BT',
        frequency: ChecklistFrequency.quarterly,
        description: description,
        notes: 'Includes all monthly items',
      ));
    }

    // Add BT yearly items
    await addItem(ChecklistItem(
      equipmentId: equipmentId,
      categoryName: 'BT',
      frequency: ChecklistFrequency.yearly,
      description: 'Complete yearly checklist',
      notes: 'Includes all items from BT Quarterly and 6-Monthly',
    ));

    // Add TER daily items
    for (final description in terDailyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'TER',
        frequency: ChecklistFrequency.daily,
        description: description,
      ));
    }

    // Add TER weekly items
    for (final description in terWeeklyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'TER',
        frequency: ChecklistFrequency.weekly,
        description: description,
      ));
    }

    // Add TER monthly items
    for (final description in terMonthlyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'TER',
        frequency: ChecklistFrequency.monthly,
        description: description,
        notes: 'Includes all daily items',
      ));
    }

    // Add TER quarterly items
    for (final description in terQuarterlyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'TER',
        frequency: ChecklistFrequency.quarterly,
        description: description,
        notes: 'Includes all monthly items',
      ));
    }

    // Add TER 6-monthly items in yearly
    for (final description in terSixMonthlyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'TER',
        frequency: ChecklistFrequency.yearly,
        description: description,
        notes: '6-Monthly item',
      ));
    }

    // Add TER yearly items
    for (final description in terYearlyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'TER',
        frequency: ChecklistFrequency.yearly,
        description: description,
      ));
    }
  }

  Future<void> addBettatecChecklistItems(String equipmentId) async {
    // BETTATEC Daily Checklist Items
    final bettatecDailyItems = [
      {'description': 'Test E/STOP function on machine', 'result': 'GOOD'},
      {'description': 'Test E/STOP function on saw', 'result': 'GOOD'},
      {'description': 'Test two hand operation (TESTED)', 'result': 'YES'},
      {'description': 'Test two hand operation on saw (TESTED)', 'result': 'YES'},
      {'description': 'Are the mould clamps secure', 'result': 'YES'},
      {'description': 'Are there any water leaks', 'result': 'NO'},
      {'description': 'Are there any HYD oil leaks', 'result': 'NO'},
      {'description': 'Is the mould heater water level correct', 'result': 'YES'},
      {'description': 'Is the HYD oil level correct', 'result': 'YES'},
      {'description': 'Does the thermocouples and heaters work', 'result': 'YES'},
      {'description': 'Saw guard is operational', 'result': 'GOOD'},
      {'description': 'Saw clamps operational', 'result': 'GOOD'},
      {'description': 'Does the door safeties work', 'result': 'YES'},
      {'description': 'Are all the guards in place and secure', 'result': 'YES'},
      {'description': 'Actual HYD oil temp on thermometer', 'result': ''},
      {'description': 'Housekeeping of area and machine', 'result': 'GOOD'},
    ];

    // BETTATEC Weekly Checklist Items
    final bettatecWeeklyItems = [
      {'description': 'Check for air leaks', 'result': 'GOOD'},
      {'description': 'Clean mould surface', 'result': 'DONE'},
    ];

    // BETTATEC Monthly Checklist Items
    final bettatecMonthlyItems = [
      {'description': 'Test E/STOP function on machine', 'result': 'GOOD'},
      {'description': 'Test E/STOP function on saw', 'result': 'GOOD'},
      {'description': 'Test two hand operation (TESTED)', 'result': 'YES'},
      {'description': 'Test two hand operation on saw (TESTED)', 'result': 'YES'},
      {'description': 'Are the mould clamps secure', 'result': 'YES'},
      {'description': 'Are there any water leaks', 'result': 'NO'},
      {'description': 'Are there any HYD oil leaks', 'result': 'NO'},
      {'description': 'Is the mould heater water level correct', 'result': 'YES'},
      {'description': 'Is the HYD oil level correct', 'result': 'YES'},
      {'description': 'Does the thermocouples and heaters work', 'result': 'YES'},
      {'description': 'Saw guard is operational', 'result': 'GOOD'},
      {'description': 'Saw clamps operational', 'result': 'GOOD'},
      {'description': 'Does the door safeties work', 'result': 'YES'},
      {'description': 'Are all the guards in place and secure', 'result': 'YES'},
      {'description': 'Actual HYD oil temp on thermometer', 'result': '42'},
      {'description': 'Check for air leaks', 'result': 'GOOD'},
      {'description': 'Check HYD cylinder bolts', 'result': 'GOOD'},
      {'description': 'Check panels for loose wiring', 'result': 'GOOD'},
      {'description': 'Check saw v-belt', 'result': 'GOOD'},
      {'description': 'Check for loose connections', 'result': 'GOOD'},
      {'description': 'Oil sample for yearly required', 'result': 'NO'},
      {'description': 'Housekeeping of area and machine', 'result': 'BAD'},
    ];

    // BETTATEC Quarterly Checklist Items
    final bettatecQuarterlyItems = [
      {'description': 'Test E/STOP function on machine', 'result': 'GOOD'},
      {'description': 'Test E/STOP function on saw', 'result': 'GOOD'},
      {'description': 'Test two hand operation (TESTED)', 'result': 'YES'},
      {'description': 'Test two hand operation on saw (TESTED)', 'result': 'YES'},
      {'description': 'Are the mould clamps secure', 'result': 'YES'},
      {'description': 'Are there any water leaks', 'result': 'NO'},
      {'description': 'Are there any HYD oil leaks', 'result': 'NO'},
      {'description': 'Is the mould heater water level correct', 'result': 'YES'},
      {'description': 'Is the HYD oil level correct', 'result': 'YES'},
      {'description': 'Does the thermocouples and heaters work', 'result': 'YES'},
      {'description': 'Saw guard is operational', 'result': 'YES'},
      {'description': 'Saw clamps operational', 'result': 'YES'},
      {'description': 'Does the door safeties work', 'result': 'YES'},
      {'description': 'Are all the guards in place and secure', 'result': 'YES'},
      {'description': 'Actual HYD oil temp on thermometer', 'result': '42'},
      {'description': 'Check for air leaks', 'result': 'GOOD'},
      {'description': 'Check HYD cylinder bolts', 'result': 'GOOD'},
      {'description': 'Check panels for loose wiring', 'result': 'GOOD'},
      {'description': 'Check saw v-belt', 'result': 'GOOD'},
      {'description': 'Check granulator blades', 'result': 'GOOD'},
      {'description': 'Grease and oil slides', 'result': 'DONE'},
      {'description': 'Check loose bolts on Granulator', 'result': 'GOOD'},
      {'description': 'Check saw blade for wear', 'result': 'GOOD'},
      {'description': 'Is the Elements and thermocouples secure', 'result': 'YES'},
      {'description': 'Check all proxies are switching', 'result': 'YES'},
      {'description': 'Check for loose wiring', 'result': 'GOOD'},
      {'description': 'Check contactors and relays', 'result': 'GOOD'},
      {'description': 'Check for loose connections', 'result': 'GOOD'},
      {'description': 'Check gripper and nozzle alignment', 'result': 'GOOD'},
    ];

    // BETTATEC 6-Monthly Checklist Items
    final bettatecSixMonthlyItems = [
      {'description': 'Test E/STOP function on machine', 'result': 'GOOD'},
      {'description': 'Test E/STOP function on saw', 'result': 'GOOD'},
      {'description': 'Test two hand operation (TESTED)', 'result': 'YES'},
      {'description': 'Test two hand operation on saw (TESTED)', 'result': 'YES'},
      {'description': 'Are the mould clamps secure', 'result': 'YES'},
      {'description': 'Are there any water leaks', 'result': 'NO'},
      {'description': 'Are there any HYD oil leaks', 'result': 'NO'},
      {'description': 'Is the mould heater water level correct', 'result': 'YES'},
      {'description': 'Is the HYD oil level correct', 'result': 'YES'},
      {'description': 'Does the thermocouples and heaters work', 'result': 'YES'},
      {'description': 'Saw guard is operational', 'result': 'GOOD'},
      {'description': 'Saw clamps operational', 'result': 'GOOD'},
      {'description': 'Does the door safeties work', 'result': 'YES'},
      {'description': 'Are all the guards in place and secure', 'result': 'YES'},
      {'description': 'Actual HYD oil temp on thermometer', 'result': '42'},
      {'description': 'Check for air leaks', 'result': 'GOOD'},
      {'description': 'Check HYD cylinder bolts', 'result': 'GOOD'},
      {'description': 'Check panels for loose wiring', 'result': 'GOOD'},
      {'description': 'Check saw v-belt', 'result': 'GOOD'},
      {'description': 'Grease and oil slides', 'result': 'DONE'},
      {'description': 'Check granulator blades', 'result': 'GOOD'},
      {'description': 'Check loose bolts on Granulator', 'result': 'GOOD'},
      {'description': 'Check saw blade for wear', 'result': 'GOOD'},
      {'description': 'Is the Elements and thermocouples secure', 'result': 'YES'},
      {'description': 'Check and clean oil cooler', 'result': 'GOOD'},
      {'description': 'Clean granulator filter oil', 'result': 'GOOD'},
      {'description': 'Check field wiring', 'result': 'GOOD'},
      {'description': 'Check all proxies are switching and secure', 'result': 'YES'},
      {'description': 'Check contactors and relays', 'result': 'GOOD'},
      {'description': 'Check gripper and nozzle alignment', 'result': 'GOOD'},
    ];

    // Add daily items
    for (final item in bettatecDailyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'BT',
        frequency: ChecklistFrequency.daily,
        description: item['description']!,
        result: item['result']!,
        notes: 'BETTATEC Machine',
      ));
    }

    // Add weekly items
    for (final item in bettatecWeeklyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'BT',
        frequency: ChecklistFrequency.weekly,
        description: item['description']!,
        result: item['result']!,
        notes: 'BETTATEC Machine',
      ));
    }

    // Add monthly items
    for (final item in bettatecMonthlyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'BT',
        frequency: ChecklistFrequency.monthly,
        description: item['description']!,
        result: item['result']!,
        notes: 'BETTATEC Machine',
      ));
    }

    // Add quarterly items
    for (final item in bettatecQuarterlyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'BT',
        frequency: ChecklistFrequency.quarterly,
        description: item['description']!,
        result: item['result']!,
        notes: 'BETTATEC Machine',
      ));
    }

    // Add 6-monthly items (using yearly frequency as closest match)
    for (final item in bettatecSixMonthlyItems) {
      await addItem(ChecklistItem(
        equipmentId: equipmentId,
        categoryName: 'BT',
        frequency: ChecklistFrequency.yearly,
        description: item['description']!,
        result: item['result']!,
        notes: 'BETTATEC Machine - 6-Monthly',
      ));
    }
  }

  // Make sure we're syncing with EquipmentProvider when needed
  void syncWithEquipmentProvider(EquipmentProvider? equipmentProvider, ChecklistItem item) {
    if (equipmentProvider == null) return;
    
    final categoryId = '${item.equipmentId}_${item.categoryName}';
    final frequency = item.frequency;
    
    equipmentProvider.updateChecklistItem(categoryId, frequency, item);
  }
  
  // Extract checklist items from the EquipmentProvider to ensure all checklists are available
  Future<void> _extractChecklistsFromEquipment() async {
    try {
      debugPrint('Extracting checklist items from EquipmentProvider...');
      
      // Use a global key to access the context without needing a BuildContext parameter
      final context = WidgetsBinding.instance.renderViewElement;
      if (context == null) {
        debugPrint('No render view element available');
        return;
      }
      
      final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
      if (equipmentProvider.isLoading) {
        debugPrint('EquipmentProvider is still loading, waiting...');
        await Future.delayed(const Duration(seconds: 2));
        if (!equipmentProvider.isLoading) {
          _extractChecklistsFromEquipment();
        }
        return;
      }
      
      final allEquipment = equipmentProvider.equipmentList;
      int itemsAdded = 0;
      
      for (final equipment in allEquipment) {
        final categories = equipmentProvider.getCategoriesForEquipment(equipment.id);
        
        for (final category in categories) {
          // Get the proper category code
          String categoryCode = '';
          switch (category.type) {
            case MaintenanceCategoryType.inspectionMaintenance:
              categoryCode = 'IM';
              break;
            case MaintenanceCategoryType.basicTasks:
              categoryCode = 'BT';
              break;
            case MaintenanceCategoryType.technicalEquipmentReview:
              categoryCode = 'TER';
              break;
          }
          
          // Process each frequency and its checklist items
          category.checklists.forEach((frequency, items) {
            if (items.isEmpty) return;
            
            final key = '${equipment.id}|$categoryCode|$frequency';
            final existingItems = _checklistItems[key] ?? [];
            
            for (final item in items) {
              // Check if item already exists in _checklistItems
              final existingIndex = existingItems.indexWhere((i) => i.id == item.id);
              
              if (existingIndex == -1) {
                // Create a copy of the item with the proper categoryName
                final updatedItem = ChecklistItem(
                  id: item.id,
                  equipmentId: equipment.id,
                  categoryName: categoryCode,
                  frequency: frequency,
                  description: item.description,
                  notes: item.notes,
                  isCompleted: item.isCompleted,
                  lastCompletedDate: item.lastCompletedDate,
                  result: item.result,
                  photoUrl: item.photoUrl,
                );
                
                existingItems.add(updatedItem);
                itemsAdded++;
              }
            }
            
            // Update the checklist items
            if (existingItems.isNotEmpty) {
              _checklistItems[key] = existingItems;
            }
          });
        }
      }
      
      if (itemsAdded > 0) {
        debugPrint('Added $itemsAdded checklist items from EquipmentProvider');
        await _saveItems();
        notifyListeners();
      } else {
        debugPrint('No new checklist items found in EquipmentProvider');
      }
    } catch (e) {
      debugPrint('Error extracting checklist items from EquipmentProvider: $e');
    }
  }

  /// Creates and saves checklist items for a machine type
  Future<void> createMachineChecklists(String equipmentId, String machineType) async {
    // Generate all checklist items for this machine type
    final items = MachineChecklists.initializeAllChecklistsForMachine(equipmentId, machineType);
    
    // Save the items
    for (var item in items) {
      await addItem(item);
    }
    
    notifyListeners();
  }

  /// Gets checklist items for a specific machine type, equipment, and frequency
  List<ChecklistItem> getMachineChecklistItems(String equipmentId, String machineType, ChecklistFrequency frequency) {
    return _checklistItems.values.expand((items) => items).where((item) => 
      item.equipmentId == equipmentId && 
      item.categoryName == machineType &&
      item.frequency == frequency
    ).toList();
  }

  /// Updates an existing checklist item
  Future<void> updateChecklistItem(ChecklistItem item) async {
    // Find the item across all lists
    for (var entry in _checklistItems.entries) {
      final index = entry.value.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        entry.value[index] = item;
        await _saveItems();
        notifyListeners();
        return;
      }
    }
  }
} 