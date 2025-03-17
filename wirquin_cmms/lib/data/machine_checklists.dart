import '../models/checklist_item.dart';
import 'package:flutter/foundation.dart';

/// Machine-specific checklist templates for IM, BT, and TER machines
class MachineChecklists {
  static const Map<String, Map<String, List<Map<String, String>>>> templates = {
    'IM': {
      'Daily': [
        {'description': 'Test E/STOP function', 'example': 'GOOD'},
        {'description': 'Grease mould pillars', 'example': 'DONE'},
        {'description': 'Door stop functions in SEMI (TESTED)', 'example': 'YES'},
        {'description': 'Door stop functions in AUTO (TESTED)', 'example': 'YES'},
        {'description': 'Is the mechanical safety secure', 'example': 'YES'},
        {'description': 'Are the mould clamps secure', 'example': 'YES'},
        {'description': 'Are there any water leaks', 'example': 'NO'},
        {'description': 'Are there any HYD oil leaks', 'example': 'NO'},
        {'description': 'all the guards in place and secure', 'example': 'YES'},
        {'description': 'Housekeeping of area and machine', 'example': 'GOOD'},
        {'description': 'Actual HYD oil temp on screen', 'example': '41'},
        {'description': 'Actual HYD oil temp on thermometer', 'example': '31'},
        {'description': 'HYD oil set point', 'example': '30'},
        {'description': 'HYD oil [+ve] over set point', 'example': '15'},
        {'description': 'HYD oil [-ve] under set point', 'example': '25'},
        {'description': 'Does the thermocouples and heaters work', 'example': 'YES'},
        {'description': 'Is the lube oil level correct', 'example': 'YES'},
        {'description': 'Is the hyd oil level correct', 'example': 'YES'},
        {'description': 'Is there water flow on the barrel', 'example': 'YES'}
      ],
      'Weekly': [
        {'description': 'Check lube lines for any damages', 'example': 'GOOD'},
        {'description': 'Clean water strainer on main line', 'example': 'DONE'},
        {'description': 'Does the guard doors still close easy', 'example': 'YES'},
        {'description': 'Grease thrust bearings and slides', 'example': 'DONE'}
      ],
      'Monthly': [
        {'description': 'Test E/STOP function', 'example': 'GOOD'},
        {'description': 'Door stop functions in MAN (TESTED)', 'example': 'YES'},
        {'description': 'Door stop functions in SEMI (TESTED)', 'example': 'YES'},
        {'description': 'Door stop functions in AUTO (TESTED)', 'example': 'YES'},
        {'description': 'Is the mechanical safety secure', 'example': 'YES'},
        {'description': 'Are the mould clamps secure', 'example': 'YES'},
        {'description': 'Are there any water leaks', 'example': 'NO'},
        {'description': 'Are there any HYD oil leaks', 'example': 'NO'},
        {'description': 'Are all the guards in place and secure', 'example': 'YES'},
        {'description': 'Housekeeping of area and machine', 'example': 'GOOD'},
        {'description': 'Actual HYD oil temp on screen', 'example': '41'},
        {'description': 'Actual HYD oil temp on thermometer', 'example': '31'},
        {'description': 'HYD oil set point', 'example': '30'},
        {'description': 'HYD oil [+ve] over set point', 'example': '15'},
        {'description': 'HYD oil [-ve] under set point', 'example': '25'},
        {'description': 'Does the thermocouples and heaters work', 'example': 'YES'},
        {'description': 'Is the lube oil level correct', 'example': 'YES'},
        {'description': 'Is the hyd oil level correct', 'example': 'YES'},
        {'description': 'Check lube lines for any damages', 'example': 'GOOD'},
        {'description': 'Does the guard doors still close easy', 'example': 'YES'},
        {'description': 'Check for loose wiring', 'example': 'GOOD'},
        {'description': 'Control on working pressure', 'example': 'GOOD'},
        {'description': 'Does the pressure gauge work', 'example': 'YES'},
        {'description': 'Grease thrust bearings and slides', 'example': 'DONE'},
        {'description': 'Clean panel fan filters', 'example': 'DONE'},
        {'description': 'Does all the panel fans work', 'example': 'YES'},
        {'description': 'Oil sample for yearly required', 'example': 'NO'},
        {'description': 'Clean water strainer', 'example': 'DONE'}
      ],
      'Quarterly': [
        {'description': 'Test E/STOP function', 'example': 'GOOD'},
        {'description': 'Door stop functions in MAN (TESTED)', 'example': 'YES'},
        {'description': 'Door stop functions in SEMI (TESTED)', 'example': 'YES'},
        {'description': 'Door stop functions in AUTO (TESTED)', 'example': 'YES'},
        {'description': 'Is the mechanical safety secure', 'example': 'YES'},
        {'description': 'Are the mould clamps secure', 'example': 'YES'},
        {'description': 'Are there any water leaks', 'example': 'NO'},
        {'description': 'Are there any HYD oil leaks', 'example': 'NO'},
        {'description': 'Are all the guards in place and secure', 'example': 'YES'},
        {'description': 'Housekeeping of area and machine', 'example': 'GOOD'},
        {'description': 'Actual HYD oil temp on screen', 'example': '41'},
        {'description': 'Actual HYD oil temp on thermometer', 'example': '31'},
        {'description': 'HYD oil set point', 'example': '30'},
        {'description': 'HYD oil [+ve] over set point', 'example': '15'},
        {'description': 'HYD oil [-ve] under set point', 'example': '25'},
        {'description': 'Does the thermocouples and heaters work', 'example': 'YES'},
        {'description': 'Is the lube oil level correct', 'example': 'YES'},
        {'description': 'Is the hyd oil level correct', 'example': 'YES'},
        {'description': 'Check lube lines for any damages', 'example': 'GOOD'},
        {'description': 'Does the guard doors still close easy', 'example': 'YES'},
        {'description': 'Check for loose connections in panel', 'example': 'GOOD'},
        {'description': 'Control on working pressure', 'example': 'GOOD'},
        {'description': 'Does the pressure gauge work', 'example': 'YES'},
        {'description': 'Is the heaters and thermocouples secure', 'example': 'YES'},
        {'description': 'Check all the proxies are switching', 'example': 'GOOD'},
        {'description': 'Ensure nozzle alignment', 'example': 'GOOD'},
        {'description': 'Grease thrust bearings and slides', 'example': 'DONE'},
        {'description': 'Clean panel fan filters', 'example': 'DONE'},
        {'description': 'Does all the panel fans work', 'example': 'YES'},
        {'description': 'Clean water strainer', 'example': 'DONE'}
      ],
      '6-Monthly': [
        {'description': 'All items from IM Quarterly', 'example': ''},
        {'description': 'Check field wiring', 'example': 'GOOD'},
        {'description': 'Check contactors and relays', 'example': 'GOOD'},
        {'description': 'Check tie bar nuts secure', 'example': 'YES'},
        {'description': 'Check machine level in spec', 'example': 'YES'},
        {'description': 'Check and clean cooler', 'example': 'YES'},
        {'description': 'Check hyd filter pressure', 'example': 'GREEN'},
        {'description': 'Drain HYD oil and clean tank', 'example': 'DONE'},
        {'description': 'Was the hydraulic oil reused', 'example': 'NO'}
      ],
      'Yearly': [
        {'description': 'All items from IM 6-Monthly', 'example': ''},
        {'description': 'Check all bolts on machine is secure', 'example': 'GOOD'},
        {'description': 'Clean suction strainer/Replace if required', 'example': '------CLEANED'},
        {'description': 'Clean breather filter', 'example': 'DONE'},
        {'description': 'Check for bearing noise', 'example': 'GOOD'},
        {'description': 'Check platens Vertical and Horizontal', 'example': 'YES'},
        {'description': 'Ensure Lube setting according to chart', 'example': 'YES'},
        {'description': 'Blow out and clean servo Drive', 'example': 'DONE'},
        {'description': 'Clean flow indicators', 'example': 'DONE'},
        {'description': 'Clean water strainer', 'example': 'DONE'}
      ]
    },
    'BT': {
      'Daily': [
        {'description': 'Test E/STOP function on machine', 'example': 'GOOD'},
        {'description': 'Test E/STOP function on saw', 'example': 'GOOD'},
        {'description': 'Test two hand operation (TESTED)', 'example': 'YES'},
        {'description': 'Test two hand operation on saw (TESTED)', 'example': 'YES'},
        {'description': 'Are the mould clamps secure', 'example': 'YES'},
        {'description': 'Are there any water leaks', 'example': 'NO'},
        {'description': 'Are there any HYD oil leaks', 'example': 'NO'},
        {'description': 'Is the mould heater water level correct', 'example': 'YES'},
        {'description': 'Is the HYD oil level correct', 'example': 'YES'},
        {'description': 'Does the thermocouples and heaters work', 'example': 'YES'},
        {'description': 'Saw guard is operational', 'example': 'GOOD'},
        {'description': 'Saw clamps operational', 'example': 'GOOD'},
        {'description': 'Does the door safeties work', 'example': 'YES'},
        {'description': 'Are all the guards in place and secure', 'example': 'YES'},
        {'description': 'Actual HYD oil temp on thermometer', 'example': '42'},
        {'description': 'Housekeeping of area and machine', 'example': 'GOOD'}
      ],
      'Weekly': [
        {'description': 'Check for air leaks', 'example': 'GOOD'},
        {'description': 'Clean mould surface', 'example': 'DONE'}
      ],
      'Monthly': [
        {'description': 'All items from BT Daily', 'example': ''},
        {'description': 'Check HYD cylinder bolts', 'example': 'GOOD'},
        {'description': 'Check panels for loose wiring', 'example': 'GOOD'},
        {'description': 'Check saw v-belt', 'example': 'GOOD'},
        {'description': 'Check for loose connections', 'example': 'GOOD'},
        {'description': 'Oil sample for yearly required', 'example': 'NO'},
        {'description': 'Housekeeping of area and machine', 'example': 'BAD'}
      ],
      'Quarterly': [
        {'description': 'All items from BT Monthly', 'example': ''},
        {'description': 'Grease and oil slides', 'example': 'DONE'},
        {'description': 'Check granulator blades', 'example': 'GOOD'},
        {'description': 'Check for loose bolts on Granulator', 'example': 'GOOD'},
        {'description': 'Check saw blade for wear', 'example': 'GOOD'},
        {'description': 'Check gripper and nozzle alignment', 'example': 'GOOD'}
      ],
      '6-Monthly': [
        {'description': 'All items from BT Quarterly', 'example': ''},
        {'description': 'Check and clean oil cooler', 'example': 'GOOD'},
        {'description': 'Check granulator Gear oil', 'example': 'GOOD'}
      ],
      'Yearly': [
        {'description': 'All items from BT 6-Monthly', 'example': ''},
        {'description': 'Drain HYD oil and clean tank', 'example': 'DONE'},
        {'description': 'Was the HYD oil reused', 'example': 'NO'},
        {'description': 'Clean suction strainer/Replace if required', 'example': '------CLEANED'},
        {'description': 'Clean motor cooling fans', 'example': 'DONE'},
        {'description': 'Check for bearing noise', 'example': 'GOOD'}
      ]
    },
    'TER': {
      'Daily': [
        {'description': 'Check mould hoses not shaving', 'example': 'GOOD'},
        {'description': 'Check mould hoses not leaking on coupling', 'example': 'GOOD'},
        {'description': 'Check Mould clamps secure', 'example': 'YES'},
        {'description': 'Are there any water leaks', 'example': 'NO'},
        {'description': 'Are there any HYD oil leaks', 'example': 'NO'},
        {'description': 'Door open motor stop functional LH/RH', 'example': 'YES'},
        {'description': 'Are all the guards in place and secure', 'example': 'YES'},
        {'description': 'HYD oil temp on screen LH/RH', 'example': '44/36'},
        {'description': 'is the HYD oil level correct LH/RH', 'example': 'YES'},
        {'description': 'Grease mould pillars LH & RH', 'example': 'DONE'},
        {'description': 'Clean pillar holes LH & RH', 'example': 'DONE'},
        {'description': 'Test all E/STOPS', 'example': 'GOOD'},
        {'description': 'Test safety curtain', 'example': 'YES'},
        {'description': 'Are the platens Warm to touch', 'example': 'NO'},
        {'description': 'CLEAN ALL FLASH FROM PLATENS', 'example': 'DONE'}
      ],
      'Weekly': [
        {'description': 'Clean all panel filters', 'example': 'DONE'},
        {'description': 'Clean water Strainer on main line', 'example': 'DONE'},
        {'description': 'Check shutter bolts secure', 'example': 'DONE'},
        {'description': 'Does the doors still open/close easy', 'example': 'YES'},
        {'description': 'Check whisker protector secure', 'example': 'GOOD'}
      ],
      'Monthly': [
        {'description': 'All items from TER Weekly', 'example': ''},
        {'description': 'Check for air leaks', 'example': 'GOOD'},
        {'description': 'Grease loader/unloader slides', 'example': 'DONE'},
        {'description': 'Check island interlock', 'example': 'GOOD'},
        {'description': 'Check indication globes/replace', 'example': 'GOOD'},
        {'description': 'Check for loose connections in panels', 'example': 'GOOD'},
        {'description': 'Control on working pressure', 'example': 'GOOD'},
        {'description': 'Does the pressure gauge work', 'example': 'YES'}
      ],
      'Quarterly': [
        {'description': 'All items from TER Monthly', 'example': ''},
        {'description': 'Ensure Ejector head and ext. secure', 'example': 'DONE'},
        {'description': 'Grease tie bars', 'example': 'DONE'},
        {'description': 'Check all thermocouples secure', 'example': 'GOOD'},
        {'description': 'Clean debris out of oil pan', 'example': 'DONE'},
        {'description': 'Check HYD air filter/replace if required', 'example': 'GOOD'},
        {'description': 'Clean linear units of any deposits', 'example': 'DONE'},
        {'description': 'Check ejector sensors secure', 'example': 'GOOD'},
        {'description': 'TAKE OIL SAMPLE', 'example': 'DONE'}
      ],
      '6-Monthly': [
        {'description': 'All items from TER Quarterly', 'example': ''},
        {'description': 'Re-Torque platen bolts', 'example': 'DONE'},
        {'description': 'Check all other bolts secure on machine', 'example': 'GOOD'},
        {'description': 'Check tie bar nuts 0.05mm to beam', 'example': 'DONE'},
        {'description': 'Replace filter media of panel fans', 'example': 'DONE'},
        {'description': 'Check and clean oil cooler', 'example': 'GOOD'},
        {'description': 'Check water flow on platens', 'example': 'GOOD'},
        {'description': 'Check for oil leaks on main Ram', 'example': 'GOOD'}
      ],
      'Yearly': [
        {'description': 'All items from TER 6-Monthly', 'example': ''},
        {'description': 'Drain HYD oil and clean tank LH/RH', 'example': 'DONE'},
        {'description': 'Was the HYD oil reused', 'example': 'YES'},
        {'description': 'Drain DIATHERMIC oil and replace', 'example': 'DONE'},
        {'description': 'Clean suction strainer/Replace if required', 'example': 'DONE'},
        {'description': 'Clean motors and cooling fans', 'example': 'DONE'},
        {'description': 'Check for bearing noise', 'example': 'GOOD'},
        {'description': 'Open and clean water ports', 'example': 'DONE'},
        {'description': 'Check ejector sensors secure', 'example': 'GOOD'},
        {'description': 'Disconnect/reconnect all thermocouple wires', 'example': ''}
      ]
    }
  };

  /// Helper method to get the frequency string from enum
  static String getStringFromFrequency(ChecklistFrequency frequency) {
    switch (frequency) {
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
      default:
        return 'Daily';
    }
  }
  
  /// Helper method to get the frequency enum from string
  static ChecklistFrequency getFrequencyFromString(String frequencyString) {
    switch (frequencyString) {
      case 'Daily':
        return ChecklistFrequency.daily;
      case 'Weekly':
        return ChecklistFrequency.weekly;
      case 'Monthly':
        return ChecklistFrequency.monthly;
      case 'Quarterly':
        return ChecklistFrequency.quarterly;
      case '6-Monthly':
        return ChecklistFrequency.yearly; // Map 6-Monthly to yearly for now
      case 'Yearly':
        return ChecklistFrequency.yearly;
      default:
        return ChecklistFrequency.daily;
    }
  }

  /// Creates checklist items for a specific equipment, machine type and frequency
  static List<ChecklistItem> createChecklistItems({
    required String equipmentId,
    required String machineType,
    required ChecklistFrequency frequency,
  }) {
    print('Creating checklist items for $machineType with frequency ${getStringFromFrequency(frequency)}');
    
    // Handle 6-Monthly specially because it doesn't map directly to an enum
    String frequencyString = getStringFromFrequency(frequency);
    
    // Special case: if it's yearly, also check for 6-Monthly items
    if (frequency == ChecklistFrequency.yearly) {
      final sixMonthlyItems = templates[machineType]?['6-Monthly'] ?? [];
      final yearlyItems = templates[machineType]?['Yearly'] ?? [];
      
      final sixMonthlyResults = sixMonthlyItems.map((template) => ChecklistItem(
        equipmentId: equipmentId,
        categoryName: machineType,
        frequency: ChecklistFrequency.yearly,
        description: template['description'] ?? '',
        result: '',
        isCompleted: false,
      )).toList();
      
      final yearlyResults = yearlyItems.map((template) => ChecklistItem(
        equipmentId: equipmentId,
        categoryName: machineType,
        frequency: ChecklistFrequency.yearly,
        description: template['description'] ?? '',
        result: '',
        isCompleted: false,
      )).toList();
      
      print('Created ${sixMonthlyResults.length} 6-Monthly items and ${yearlyResults.length} Yearly items');
      return [...sixMonthlyResults, ...yearlyResults];
    }
    
    final items = templates[machineType]?[frequencyString] ?? [];
    print('Found ${items.length} template items for $machineType $frequencyString');
    
    final results = items.map((template) => ChecklistItem(
      equipmentId: equipmentId,
      categoryName: machineType,
      frequency: frequency,
      description: template['description'] ?? '',
      result: '',
      isCompleted: false,
    )).toList();
    
    print('Created ${results.length} checklist items for $machineType $frequencyString');
    return results;
  }
  
  /// Initializes all checklist items for a given equipment and machine type
  static List<ChecklistItem> initializeAllChecklistsForMachine(String equipmentId, String machineType) {
    List<ChecklistItem> allItems = [];
    
    // Check if this machine type has templates
    final machineTemplates = templates[machineType];
    if (machineTemplates == null || machineTemplates.isEmpty) {
      // If no templates exist for this machine type, use generic templates
      debugPrint('No templates found for $machineType, using generic templates');
      return _createGenericChecklistItems(equipmentId, machineType);
    }
    
    // Create items for each frequency
    for (var frequency in ChecklistFrequency.values) {
      final items = createChecklistItems(
        equipmentId: equipmentId,
        machineType: machineType,
        frequency: frequency,
      );
      allItems.addAll(items);
    }
    
    return allItems;
  }
  
  /// Creates generic checklist items when no templates exist for a machine type
  static List<ChecklistItem> _createGenericChecklistItems(String equipmentId, String machineType) {
    List<ChecklistItem> allItems = [];
    
    // Create items for each frequency with generic tasks
    for (var frequency in ChecklistFrequency.values) {
      List<Map<String, String>> genericItems = [];
      
      switch (frequency) {
        case ChecklistFrequency.daily:
          genericItems = [
            {'description': 'Inspect machine for any visible damage'},
            {'description': 'Check safety systems functionality'},
            {'description': 'Verify proper operation at startup'},
            {'description': 'Clean work area around machine'},
          ];
          break;
        case ChecklistFrequency.weekly:
          genericItems = [
            {'description': 'Check fluid levels'},
            {'description': 'Inspect belts and hoses for wear'},
            {'description': 'Clean air filters'},
          ];
          break;
        case ChecklistFrequency.monthly:
          genericItems = [
            {'description': 'Perform full lubrication of moving parts'},
            {'description': 'Check electrical connections'},
            {'description': 'Inspect for loose bolts and connectors'},
          ];
          break;
        case ChecklistFrequency.quarterly:
          genericItems = [
            {'description': 'Check calibration of sensors'},
            {'description': 'Inspect bearings for wear'},
            {'description': 'Clean cooling systems'},
          ];
          break;
        case ChecklistFrequency.yearly:
          genericItems = [
            {'description': 'Perform comprehensive maintenance inspection'},
            {'description': 'Replace worn parts as needed'},
            {'description': 'Update maintenance documentation'},
          ];
          break;
      }
      
      // Create items from generic templates
      final items = genericItems.map((template) => ChecklistItem(
        equipmentId: equipmentId,
        categoryName: machineType,
        frequency: frequency,
        description: template['description'] ?? '',
        result: '',
        isCompleted: false,
      )).toList();
      
      allItems.addAll(items);
    }
    
    return allItems;
  }
} 