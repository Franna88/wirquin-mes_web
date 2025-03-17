import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:equipment_app/providers/checklist_provider.dart';
import 'package:equipment_app/models/equipment.dart';
import 'package:equipment_app/utils/debug_utils.dart';

class EquipmentProvider {
  // Add sample equipment for testing
  Future<void> addSampleEquipment() async {
    _setLoading(true);
    
    try {
      // Sample equipment data
      final sampleEquipment = [
        Equipment(
          id: 'equipment_ext_001',
          name: 'Extruder Machine 1',
          location: 'Production Hall A',
          machineType: 'Extruder',
          serialNumber: 'EXT-2023-001',
          manufacturer: 'Wirquin',
        ),
        Equipment(
          id: 'equipment_inj_002',
          name: 'Injection Moulding Machine 2',
          location: 'Production Hall B',
          machineType: 'Injection Moulding',
          serialNumber: 'INJ-2023-002',
          manufacturer: 'Wirquin',
        ),
        Equipment(
          id: 'equipment_pkg_003',
          name: 'Packaging Line 3',
          location: 'Packaging Department',
          machineType: 'Packaging',
          serialNumber: 'PKG-2023-003',
          manufacturer: 'Wirquin',
        ),
        Equipment(
          id: 'equipment_cnc_004',
          name: 'CNC Machine 4',
          location: 'Machining Department',
          machineType: 'CNC',
          serialNumber: 'CNC-2023-004',
          manufacturer: 'Wirquin',
        ),
      ];
      
      // Add equipment to the list
      for (var equipment in sampleEquipment) {
        await addOrUpdateEquipment(equipment);
        
        // Create default maintenance categories for each equipment
        await _createDefaultMaintenanceCategories(equipment.id);
        
        // Add default checklists for ALL equipment (not just injection molding)
        await addInjectionMouldingChecklists(equipment.id);
        
        // Get access to ChecklistProvider to add default checklist items
        Future.delayed(const Duration(seconds: 1), () {
          final context = WidgetsBinding.instance.renderViewElement;
          if (context != null) {
            try {
              final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
              checklistProvider.addDefaultChecklistItems(equipment.id);
              debugPrint('Added default checklist items for equipment: ${equipment.name}');
            } catch (e) {
              debugPrint('Error adding default checklist items: $e');
            }
          }
        });
      }
      
      debugPrint('Added ${sampleEquipment.length} sample equipment items');
    } catch (e) {
      _error = 'Error adding sample equipment: $e';
    } finally {
      _setLoading(false);
    }
  }
} 