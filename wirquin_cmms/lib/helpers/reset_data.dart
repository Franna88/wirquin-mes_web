import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../providers/equipment_provider.dart';

Future<void> resetApplicationData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear equipment data
    await prefs.remove('equipment_list');
    
    // Clear maintenance categories
    await prefs.remove('maintenance_categories');
    
    // Clear checklist items
    await prefs.remove('checklist_items');
    
    // Clear user data if needed
    // await prefs.remove('user_data');
    
    debugPrint('🔄 Application data has been reset!');
  } catch (e) {
    debugPrint('Error resetting application data: $e');
  }
}

Future<void> resetAndReload(EquipmentProvider equipmentProvider) async {
  try {
    // First reset all saved data
    await resetApplicationData();
    
    // Then trigger reload in the provider
    await equipmentProvider.reloadData();
    
    debugPrint('✅ Application data reset and reloaded!');
  } catch (e) {
    debugPrint('Error in reset and reload: $e');
  }
} 