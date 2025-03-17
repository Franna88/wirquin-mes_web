import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../providers/equipment_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import '../providers/checklist_provider.dart';
import '../models/equipment.dart';
import '../data/machine_checklists.dart';
import 'dart:math' show min;

Future<void> resetApplicationData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    debugPrint('⚠️ Starting application data reset!');
    
    // Clear all shared preferences data
    await prefs.clear();
    
    // Explicitly clear specific keys
    debugPrint('Clearing equipment_list');
    await prefs.remove('equipment_list');
    
    debugPrint('Clearing maintenance_categories');
    await prefs.remove('maintenance_categories');
    
    debugPrint('Clearing checklist_items');
    await prefs.remove('checklist_items');
    
    // Clear any other data
    debugPrint('Clearing user_data');
    await prefs.remove('user_data');
    
    debugPrint('🔄 Application data has been reset!');
  } catch (e) {
    debugPrint('Error resetting application data: $e');
  }
}

Future<void> resetAndReload(EquipmentProvider equipmentProvider) async {
  try {
    debugPrint('🚀 Starting reset and reload process');
    
    // First reset all saved data
    await resetApplicationData();
    
    // Then trigger reload in the provider which will create sample equipment
    debugPrint('Reloading equipment data');
    await equipmentProvider.reloadData();
    
    // After the equipment is created, force regenerate all checklists for all equipment
    final equipment = equipmentProvider.equipmentList;
    debugPrint('Found ${equipment.length} equipment items - regenerating all checklists');
    
    // Clear existing checklist data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('checklist_items');
    
    // Get a context to access ChecklistProvider if possible
    final context = WidgetsBinding.instance.renderViewElement;
    ChecklistProvider? checklistProvider;
    if (context != null) {
      try {
        checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
      } catch (e) {
        debugPrint('Could not access ChecklistProvider: $e');
      }
    }
    
    for (var machine in equipment) {
      debugPrint('✅ Regenerating ALL checklists for ${machine.name}');
      
      // Generate all three types of checklists for each machine 
      final machineTypes = ['IM', 'BT', 'TER'];
      
      for (var type in machineTypes) {
        debugPrint('Generating $type checklists for ${machine.name}');
        final items = MachineChecklists.initializeAllChecklistsForMachine(machine.id, type);
        
        // If we have access to the ChecklistProvider, use it
        if (checklistProvider != null) {
          for (var item in items) {
            await checklistProvider.addItem(item);
          }
        }
        
        // Always add directly to EquipmentProvider as a fallback
        await equipmentProvider.addChecklistsDirectly(machine.id, type, items);
        
        debugPrint('Created ${items.length} $type checklist items for ${machine.name}');
      }
    }
    
    debugPrint('✅ Application data reset and reloaded with ${equipment.length} machines');
    debugPrint('🔍 All machines now have complete IM, BT, and TER checklists!');
  } catch (e) {
    debugPrint('Error in reset and reload: $e');
  }
}

// Function to create a new machine with default checklists
Future<void> createNewMachineWithChecklists(
  EquipmentProvider equipmentProvider,
  String name,
  String machineType,
  String location
) async {
  try {
    debugPrint('🏭 Creating new machine: $name');
    
    // Create a new equipment object
    final equipment = Equipment(
      id: 'equipment_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      location: location,
      department: 'Production',
      machineType: machineType,
      serialNumber: 'SN-${DateTime.now().millisecondsSinceEpoch}',
      manufacturer: 'Wirquin',
      model: 'Model-${machineType.substring(0, min(3, machineType.length)).toUpperCase()}',
      installationDate: DateTime.now().toString().split(' ')[0],
      lastMaintenanceDate: DateTime.now().toString().split(' ')[0],
      status: 'Operational',
    );
    
    // Add the equipment to the provider
    debugPrint('Adding equipment to provider: ${equipment.id}');
    await equipmentProvider.addOrUpdateEquipment(equipment);
    
    // Create categories for IM, BT, and TER (regardless of the machine's type)
    debugPrint('Creating maintenance categories for: ${equipment.id}');
    await equipmentProvider.addInjectionMouldingChecklists(equipment.id);
    
    // Try to reach the ChecklistProvider to add checklist items of all three types
    final context = WidgetsBinding.instance.renderViewElement;
    if (context != null) {
      try {
        final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
        
        // Create checklists for all three types (IM, BT, TER)
        final machineTypes = ['IM', 'BT', 'TER'];
        
        for (final type in machineTypes) {
          // Initialize checklist items for this type
          final checklistItems = MachineChecklists.initializeAllChecklistsForMachine(equipment.id, type);
          debugPrint('Initialized ${checklistItems.length} checklist items for $type');
          
          // Add each checklist item
          for (final item in checklistItems) {
            await checklistProvider.addItem(item);
          }
          
          // Also try the createMachineChecklists method
          await checklistProvider.createMachineChecklists(equipment.id, type);
          debugPrint('Created $type checklists for ${equipment.name}');
        }
      } catch (e) {
        debugPrint('Error adding checklists via ChecklistProvider: $e');
      }
    }
    
    debugPrint('✅ Created new machine ${equipment.name} with all checklist types (IM, BT, TER)!');
  } catch (e) {
    debugPrint('Error creating new machine with checklists: $e');
  }
} 