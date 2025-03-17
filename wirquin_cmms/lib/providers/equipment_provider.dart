import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/equipment.dart';
import '../models/maintenance_category.dart';
import '../models/checklist_item.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/checklist_provider.dart';
import 'package:uuid/uuid.dart';

class EquipmentProvider extends ChangeNotifier {
  List<Equipment> _equipmentList = [];
  List<MaintenanceCategory> _maintenanceCategories = [];
  bool _isLoading = false;
  String _error = '';
  Map<String, ChecklistItem> _checklistItems = {};

  // Getters
  List<Equipment> get equipmentList => _equipmentList;
  List<MaintenanceCategory> get maintenanceCategories => _maintenanceCategories;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Constructor
  EquipmentProvider() {
    _loadData();
  }

  // Load data from shared preferences
  Future<void> _loadData() async {
    _setLoading(true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load equipment
      final equipmentJson = prefs.getString('equipment_list');
      if (equipmentJson != null) {
        final List decodedData = jsonDecode(equipmentJson);
        _equipmentList = decodedData
            .map((item) => Equipment.fromJson(item))
            .toList();
      }
      
      // Load maintenance categories
      final categoriesJson = prefs.getString('maintenance_categories');
      if (categoriesJson != null) {
        final List decodedData = jsonDecode(categoriesJson);
        _maintenanceCategories = decodedData
            .map((item) => MaintenanceCategory.fromJson(item))
            .toList();
      }
      
      // Remove any duplicate maintenance categories
      await removeDuplicateCategories();
      
      // Debug: print loaded equipment
      debugPrint('Loaded ${_equipmentList.length} equipment items:');
      for (var equip in _equipmentList) {
        debugPrint('Equipment: ${equip.id}, ${equip.name}, ${equip.machineType}');
      }
      
      // If no equipment is loaded, add sample equipment
      if (_equipmentList.isEmpty) {
        await addSampleEquipment();
      } else {
        // Make sure ALL existing machines have proper categories (but don't create duplicates)
        bool checklistsAdded = false;
        
        for (var equipment in _equipmentList) {
          // Get all categories for this equipment
          final categories = getCategoriesForEquipment(equipment.id);
          
          // Check how many category types exist
          final existingTypes = categories.map((c) => c.type).toSet();
          final requiredTypes = {
            MaintenanceCategoryType.inspectionMaintenance,
            MaintenanceCategoryType.basicTasks,
            MaintenanceCategoryType.technicalEquipmentReview,
          };
          
          // If we're missing any categories, create them
          if (existingTypes.length < requiredTypes.length) {
            await _createDefaultMaintenanceCategories(equipment.id);
            checklistsAdded = true;
          }
          
          // Reload categories after potentially creating new ones
          final updatedCategories = getCategoriesForEquipment(equipment.id);
          
          // Check if categories have checklists
          final hasValidChecklists = updatedCategories.any((category) {
            return category.checklists.values.any((items) => items.isNotEmpty);
          });
          
          // If no valid checklists found, add them directly using addInjectionMouldingChecklists
          if (!hasValidChecklists) {
            debugPrint('Adding checklists to ${equipment.name}');
            await addInjectionMouldingChecklists(equipment.id);
            checklistsAdded = true;
          }
        }
        
        // If we added checklists, save the data
        if (checklistsAdded) {
          await _saveData();
        }
        
        // Attempt to add default checklist items via ChecklistProvider as a backup
        await Future.delayed(const Duration(seconds: 2));
        final context = WidgetsBinding.instance.renderViewElement;
        if (context != null) {
          try {
            final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
            for (var equipment in _equipmentList) {
              await checklistProvider.addDefaultChecklistItems(equipment.id);
              debugPrint('Added additional default checklist items to ${equipment.name}');
            }
          } catch (e) {
            debugPrint('Error adding default checklist items: $e');
          }
        }
      }
      
    } catch (e) {
      _error = 'Error loading data: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Save data to shared preferences
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save equipment
      final equipmentJson = jsonEncode(_equipmentList.map((e) => e.toJson()).toList());
      await prefs.setString('equipment_list', equipmentJson);
      
      // Save maintenance categories
      final categoriesJson = jsonEncode(_maintenanceCategories.map((c) => c.toJson()).toList());
      await prefs.setString('maintenance_categories', categoriesJson);
    } catch (e) {
      _error = 'Error saving data: $e';
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Add or update equipment
  Future<void> addOrUpdateEquipment(Equipment equipment) async {
    _setLoading(true);
    
    try {
      final index = _equipmentList.indexWhere((e) => e.id == equipment.id);
      bool isNewEquipment = index < 0;
      
      if (index >= 0) {
        // Update existing equipment
        _equipmentList[index] = equipment;
      } else {
        // Add new equipment
        _equipmentList.add(equipment);
        
        // Create default maintenance categories for new equipment
        // (only if they don't already exist)
        await _createDefaultMaintenanceCategories(equipment.id);
        
        // Schedule a delayed task to add default checklist items
        Future.delayed(const Duration(seconds: 1), () {
          // Access ChecklistProvider without BuildContext
          final context = WidgetsBinding.instance.renderViewElement;
          if (context != null) {
            try {
              final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
              checklistProvider.addDefaultChecklistItems(equipment.id);
              debugPrint('Added default checklist items for new equipment: ${equipment.name}');
            } catch (e) {
              debugPrint('Error adding default checklist items: $e');
            }
          }
        });
      }
      
      await _saveData();
      
      // If this is new equipment, we should add default checklists immediately
      if (isNewEquipment) {
        await addInjectionMouldingChecklists(equipment.id);
      }
    } catch (e) {
      _error = 'Error adding/updating equipment: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Delete equipment
  Future<void> deleteEquipment(String equipmentId) async {
    _setLoading(true);
    
    try {
      _equipmentList.removeWhere((e) => e.id == equipmentId);
      
      // Also remove associated maintenance categories
      _maintenanceCategories.removeWhere((c) => c.equipmentId == equipmentId);
      
      await _saveData();
    } catch (e) {
      _error = 'Error deleting equipment: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Get equipment by ID
  Equipment? getEquipmentById(String id) {
    try {
      return _equipmentList.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get maintenance categories for equipment
  List<MaintenanceCategory> getCategoriesForEquipment(String equipmentId) {
    return _maintenanceCategories.where((c) => c.equipmentId == equipmentId).toList();
  }

  // Add or update maintenance category
  Future<void> addOrUpdateMaintenanceCategory(MaintenanceCategory category) async {
    _setLoading(true);
    
    try {
      final index = _maintenanceCategories.indexWhere((c) => c.id == category.id);
      
      if (index >= 0) {
        // Update existing category
        _maintenanceCategories[index] = category;
      } else {
        // Add new category
        _maintenanceCategories.add(category);
      }
      
      await _saveData();
    } catch (e) {
      _error = 'Error adding/updating maintenance category: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Get checklist items for a specific category and frequency
  List<ChecklistItem> getChecklistItems(String categoryId, ChecklistFrequency frequency) {
    try {
      final category = _maintenanceCategories.firstWhere((c) => c.id == categoryId);
      return category.checklists[frequency] ?? [];
    } catch (e) {
      return [];
    }
  }

  // Update checklist item
  Future<void> updateChecklistItem(
    String categoryId, 
    ChecklistFrequency frequency, 
    ChecklistItem item
  ) async {
    _setLoading(true);
    
    try {
      final categoryIndex = _maintenanceCategories.indexWhere((c) => c.id == categoryId);
      
      if (categoryIndex >= 0) {
        final category = _maintenanceCategories[categoryIndex];
        final checklist = category.checklists[frequency] ?? [];
        
        final itemIndex = checklist.indexWhere((i) => i.id == item.id);
        
        if (itemIndex >= 0) {
          // Update existing item
          checklist[itemIndex] = item;
        } else {
          // Add new item
          checklist.add(item);
        }
        
        // Create updated category with modified checklist
        final updatedChecklists = Map<ChecklistFrequency, List<ChecklistItem>>.from(category.checklists);
        updatedChecklists[frequency] = checklist;
        
        final updatedCategory = MaintenanceCategory(
          id: category.id,
          equipmentId: category.equipmentId,
          type: category.type,
          checklists: updatedChecklists,
        );
        
        _maintenanceCategories[categoryIndex] = updatedCategory;
        
        await _saveData();
      }
    } catch (e) {
      _error = 'Error updating checklist item: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Add sample equipment for testing
  Future<void> addSampleEquipment() async {
    _setLoading(true);
    
    try {
      final sampleEquipment = [
        Equipment(
          id: 'equipment_ext_001',
          name: 'Extruder Machine 1',
          location: 'Production Floor A',
          department: 'Production',
          machineType: 'Extruder',
          serialNumber: 'EXT-2023-001',
          manufacturer: 'ExtruTech',
          model: 'EX-5000',
          installationDate: '2023-01-15',
          lastMaintenanceDate: '2023-04-20',
          status: 'Operational',
        ),
        Equipment(
          id: 'equipment_inj_002',
          name: 'Injection Moulding Machine 2',
          location: 'Production Floor B',
          department: 'Production',
          machineType: 'Injection Moulding',
          serialNumber: 'INJ-2023-002',
          manufacturer: 'MoldMaster',
          model: 'IM-800',
          installationDate: '2023-02-10',
          lastMaintenanceDate: '2023-05-12',
          status: 'Operational',
        ),
        Equipment(
          id: 'equipment_pkg_003',
          name: 'Packaging Line 3',
          location: 'Packaging Area',
          department: 'Packaging',
          machineType: 'Packaging',
          serialNumber: 'PKG-2023-003',
          manufacturer: 'PackSys',
          model: 'PL-2000',
          installationDate: '2023-03-05',
          lastMaintenanceDate: '2023-06-01',
          status: 'Operational',
        ),
        Equipment(
          id: 'equipment_cnc_004',
          name: 'CNC Machine 4',
          location: 'Machining Area',
          department: 'Machining',
          machineType: 'CNC',
          serialNumber: 'CNC-2023-004',
          manufacturer: 'CNCTech',
          model: 'CNC-X500',
          installationDate: '2023-04-20',
          lastMaintenanceDate: '2023-06-15',
          status: 'Operational',
        ),
      ];
      
      // First, add all equipment to the list and create their default maintenance categories
      for (var equipment in sampleEquipment) {
        // Add equipment to the list
        _equipmentList.add(equipment);
        
        // Create default maintenance categories for new equipment
        await _createDefaultMaintenanceCategories(equipment.id);
        
        debugPrint('Added equipment: ${equipment.name}');
      }
      
      // Save the equipment data
      await _saveData();
      
      // Now add checklists to each equipment with a small delay between each
      for (var equipment in sampleEquipment) {
        debugPrint('Adding checklists to ${equipment.name}');
        await addInjectionMouldingChecklists(equipment.id);
      }
      
      debugPrint('Added ${sampleEquipment.length} sample equipment items');
    } catch (e) {
      _error = 'Error adding sample equipment: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Create default maintenance categories for equipment
  Future<void> _createDefaultMaintenanceCategories(String equipmentId) async {
    try {
      // First check if categories already exist for this equipment
      final existingCategories = getCategoriesForEquipment(equipmentId);
      final existingCategoryTypes = existingCategories.map((c) => c.type).toSet();
      
      final categoryTypes = [
        MaintenanceCategoryType.inspectionMaintenance,
        MaintenanceCategoryType.basicTasks,
        MaintenanceCategoryType.technicalEquipmentReview,
      ];
      
      int categoriesCreated = 0;
      
      for (var type in categoryTypes) {
        // Skip if this category type already exists for this equipment
        if (existingCategoryTypes.contains(type)) {
          continue;
        }
        
        final category = MaintenanceCategory(
          id: '${equipmentId}_${type.code}',
          equipmentId: equipmentId,
          type: type,
        );
        
        await addOrUpdateMaintenanceCategory(category);
        categoriesCreated++;
      }
      
      if (categoriesCreated > 0) {
        debugPrint('Created $categoriesCreated new maintenance categories for equipment $equipmentId');
      } else if (existingCategories.isNotEmpty) {
        debugPrint('No new categories created - all required categories already exist for equipment $equipmentId');
      }
    } catch (e) {
      _error = 'Error creating default maintenance categories: $e';
      debugPrint(_error);
    }
  }

  // Add sample checklist items to an existing equipment's maintenance categories
  Future<void> addSampleChecklistItems(String equipmentId) async {
    _setLoading(true);
    
    try {
      final categories = getCategoriesForEquipment(equipmentId);
      
      if (categories.isEmpty) {
        debugPrint('No maintenance categories found for equipment $equipmentId');
        return;
      }
      
      // Find IM category
      final imCategory = categories.firstWhere(
        (c) => c.type == MaintenanceCategoryType.inspectionMaintenance,
        orElse: () => categories.first,
      );
      
      // Add daily checklist items for IM
      final dailyItems = [
        ChecklistItem(
          equipmentId: equipmentId,
          categoryName: imCategory.type.code,
          frequency: ChecklistFrequency.daily,
          description: 'Inspect equipment for visible damage',
        ),
        ChecklistItem(
          equipmentId: equipmentId,
          categoryName: imCategory.type.code,
          frequency: ChecklistFrequency.daily,
          description: 'Check fluid levels',
        ),
        ChecklistItem(
          equipmentId: equipmentId,
          categoryName: imCategory.type.code,
          frequency: ChecklistFrequency.daily,
          description: 'Verify safety systems are operational',
        ),
      ];
      
      // Add weekly checklist items for IM
      final weeklyItems = [
        ChecklistItem(
          equipmentId: equipmentId,
          categoryName: imCategory.type.code,
          frequency: ChecklistFrequency.weekly,
          description: 'Clean filters',
        ),
        ChecklistItem(
          equipmentId: equipmentId,
          categoryName: imCategory.type.code,
          frequency: ChecklistFrequency.weekly,
          description: 'Lubricate moving parts',
        ),
      ];
      
      // Add monthly checklist items for IM
      final monthlyItems = [
        ChecklistItem(
          equipmentId: equipmentId,
          categoryName: imCategory.type.code,
          frequency: ChecklistFrequency.monthly,
          description: 'Check electrical connections',
        ),
        ChecklistItem(
          equipmentId: equipmentId,
          categoryName: imCategory.type.code,
          frequency: ChecklistFrequency.monthly,
          description: 'Inspect belts and hoses',
        ),
      ];
      
      // Update IM category with new checklist items
      final Map<ChecklistFrequency, List<ChecklistItem>> imChecklists = {
        ...imCategory.checklists,
        ChecklistFrequency.daily: [...(imCategory.checklists[ChecklistFrequency.daily] ?? []), ...dailyItems],
        ChecklistFrequency.weekly: [...(imCategory.checklists[ChecklistFrequency.weekly] ?? []), ...weeklyItems],
        ChecklistFrequency.monthly: [...(imCategory.checklists[ChecklistFrequency.monthly] ?? []), ...monthlyItems],
      };
      
      final updatedImCategory = MaintenanceCategory(
        id: imCategory.id,
        equipmentId: imCategory.equipmentId,
        type: imCategory.type,
        checklists: imChecklists,
      );
      
      await addOrUpdateMaintenanceCategory(updatedImCategory);
      
      // Find BT category (Basic Tasks)
      final btCategory = categories.firstWhere(
        (c) => c.type == MaintenanceCategoryType.basicTasks,
        orElse: () => categories.first,
      );
      
      // Basic Tasks checklists
      final btWeeklyItems = [
        ChecklistItem(
          equipmentId: equipmentId,
          categoryName: btCategory.type.code,
          frequency: ChecklistFrequency.weekly,
          description: 'Clean work area',
        ),
        ChecklistItem(
          equipmentId: equipmentId,
          categoryName: btCategory.type.code,
          frequency: ChecklistFrequency.weekly,
          description: 'Check inventory of spare parts',
        ),
      ];
      
      // Update BT category with new checklist items
      final Map<ChecklistFrequency, List<ChecklistItem>> btChecklists = {
        ...btCategory.checklists,
        ChecklistFrequency.weekly: [...(btCategory.checklists[ChecklistFrequency.weekly] ?? []), ...btWeeklyItems],
      };
      
      final updatedBtCategory = MaintenanceCategory(
        id: btCategory.id,
        equipmentId: btCategory.equipmentId,
        type: btCategory.type,
        checklists: btChecklists,
      );
      
      await addOrUpdateMaintenanceCategory(updatedBtCategory);
      
      // Find TER category (Technical Equipment Review)
      final terCategory = categories.firstWhere(
        (c) => c.type == MaintenanceCategoryType.technicalEquipmentReview,
        orElse: () => categories.first,
      );
      
      // Technical Equipment Review checklists
      final terMonthlyItems = [
        ChecklistItem(
          equipmentId: equipmentId,
          categoryName: terCategory.type.code,
          frequency: ChecklistFrequency.monthly,
          description: 'Perform full system diagnostic',
        ),
        ChecklistItem(
          equipmentId: equipmentId,
          categoryName: terCategory.type.code,
          frequency: ChecklistFrequency.monthly,
          description: 'Calibrate sensors',
        ),
      ];
      
      final terQuarterlyItems = [
        ChecklistItem(
          equipmentId: equipmentId,
          categoryName: terCategory.type.code,
          frequency: ChecklistFrequency.quarterly,
          description: 'Replace worn components',
        ),
        ChecklistItem(
          equipmentId: equipmentId,
          categoryName: terCategory.type.code,
          frequency: ChecklistFrequency.quarterly,
          description: 'Test backup systems',
        ),
      ];
      
      // Update TER category with new checklist items
      final Map<ChecklistFrequency, List<ChecklistItem>> terChecklists = {
        ...terCategory.checklists,
        ChecklistFrequency.monthly: [...(terCategory.checklists[ChecklistFrequency.monthly] ?? []), ...terMonthlyItems],
        ChecklistFrequency.quarterly: [...(terCategory.checklists[ChecklistFrequency.quarterly] ?? []), ...terQuarterlyItems],
      };
      
      final updatedTerCategory = MaintenanceCategory(
        id: terCategory.id,
        equipmentId: terCategory.equipmentId,
        type: terCategory.type,
        checklists: terChecklists,
      );
      
      await addOrUpdateMaintenanceCategory(updatedTerCategory);
      
      debugPrint('Added sample checklist items for equipment $equipmentId');
    } catch (e) {
      _error = 'Error adding sample checklist items: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Add comprehensive checklist items for injection molding machines
  Future<void> addInjectionMouldingChecklists(String equipmentId) async {
    _setLoading(true);
    
    try {
      debugPrint('Adding injection moulding checklists for equipment $equipmentId');
      
      // Get categories for this equipment
      final categories = getCategoriesForEquipment(equipmentId);
      
      if (categories.isEmpty) {
        debugPrint('No maintenance categories found for equipment $equipmentId');
        await _createDefaultMaintenanceCategories(equipmentId);
      }
      
      // Reload categories
      final updatedCategories = getCategoriesForEquipment(equipmentId);
      
      // Find categories of each type
      MaintenanceCategory? imCategory;
      MaintenanceCategory? btCategory;
      MaintenanceCategory? terCategory;
      
      for (var category in updatedCategories) {
        switch (category.type) {
          case MaintenanceCategoryType.inspectionMaintenance:
            imCategory = category;
            break;
          case MaintenanceCategoryType.basicTasks:
            btCategory = category;
            break;
          case MaintenanceCategoryType.technicalEquipmentReview:
            terCategory = category;
            break;
        }
      }
      
      // IM Category - Add checklist items
      if (imCategory != null) {
        // Daily items
        final imDailyItems = [
          ChecklistItem(
            equipmentId: equipmentId,
            categoryName: imCategory.type.code,
            frequency: ChecklistFrequency.daily,
            description: 'Check for loose connections in panel',
            notes: 'Inspect all electrical connections in the control panel',
          ),
          ChecklistItem(
            equipmentId: equipmentId,
            categoryName: imCategory.type.code,
            frequency: ChecklistFrequency.daily,
            description: 'Ensure nozzle alignment',
            notes: 'Verify nozzle is properly aligned with mold sprue bushing',
          ),
          ChecklistItem(
            equipmentId: equipmentId,
            categoryName: imCategory.type.code,
            frequency: ChecklistFrequency.daily,
            description: 'Check hydraulic oil level',
            notes: 'Ensure hydraulic oil is at recommended level',
          ),
        ];
        
        // Weekly items
        final imWeeklyItems = [
          ChecklistItem(
            equipmentId: equipmentId,
            categoryName: imCategory.type.code,
            frequency: ChecklistFrequency.weekly,
            description: 'Clean mold surface',
            notes: 'Remove any residue from mold surfaces',
          ),
          ChecklistItem(
            equipmentId: equipmentId,
            categoryName: imCategory.type.code,
            frequency: ChecklistFrequency.weekly,
            description: 'Check cooling water connections',
            notes: 'Inspect cooling water system for leaks or blockages',
          ),
        ];
        
        // Monthly items
        final imMonthlyItems = [
          ChecklistItem(
            equipmentId: equipmentId,
            categoryName: imCategory.type.code,
            frequency: ChecklistFrequency.monthly,
            description: 'Lubricate moving parts',
            notes: 'Apply lubricant to all moving parts as specified in manual',
          ),
        ];
        
        // Add items to category
        await _updateCategoryChecklists(imCategory, ChecklistFrequency.daily, imDailyItems);
        await _updateCategoryChecklists(imCategory, ChecklistFrequency.weekly, imWeeklyItems);
        await _updateCategoryChecklists(imCategory, ChecklistFrequency.monthly, imMonthlyItems);
      }
      
      // BT Category - Add checklist items
      if (btCategory != null) {
        // Daily items
        final btDailyItems = [
          ChecklistItem(
            equipmentId: equipmentId,
            categoryName: btCategory.type.code,
            frequency: ChecklistFrequency.daily,
            description: 'Inspect barrel heaters',
            notes: 'Check all barrel heaters are operating correctly',
          ),
          ChecklistItem(
            equipmentId: equipmentId,
            categoryName: btCategory.type.code,
            frequency: ChecklistFrequency.daily,
            description: 'Check material feed system',
            notes: 'Ensure material is feeding correctly without blockages',
          ),
        ];
        
        // Weekly items
        final btWeeklyItems = [
          ChecklistItem(
            equipmentId: equipmentId,
            categoryName: btCategory.type.code,
            frequency: ChecklistFrequency.weekly,
            description: 'Clean hopper and feed throat',
            notes: 'Remove any contamination from material hopper and feed throat',
          ),
        ];
        
        // Monthly items
        final btMonthlyItems = [
          ChecklistItem(
            equipmentId: equipmentId,
            categoryName: btCategory.type.code,
            frequency: ChecklistFrequency.monthly,
            description: 'Inspect screw and barrel',
            notes: 'Check for wear on screw and barrel components',
          ),
        ];
        
        // Add items to category
        await _updateCategoryChecklists(btCategory, ChecklistFrequency.daily, btDailyItems);
        await _updateCategoryChecklists(btCategory, ChecklistFrequency.weekly, btWeeklyItems);
        await _updateCategoryChecklists(btCategory, ChecklistFrequency.monthly, btMonthlyItems);
      }
      
      // TER Category - Add checklist items
      if (terCategory != null) {
        // Daily items
        final terDailyItems = [
          ChecklistItem(
            equipmentId: equipmentId,
            categoryName: terCategory.type.code,
            frequency: ChecklistFrequency.daily,
            description: 'Check safety guards',
            notes: 'Ensure all safety guards are in place and functioning',
          ),
        ];
        
        // Weekly items
        final terWeeklyItems = [
          ChecklistItem(
            equipmentId: equipmentId,
            categoryName: terCategory.type.code,
            frequency: ChecklistFrequency.weekly,
            description: 'Test emergency stop buttons',
            notes: 'Verify all emergency stop buttons work correctly',
          ),
        ];
        
        // Monthly items
        final terMonthlyItems = [
          ChecklistItem(
            equipmentId: equipmentId,
            categoryName: terCategory.type.code,
            frequency: ChecklistFrequency.monthly,
            description: 'Calibrate temperature controls',
            notes: 'Verify temperature controllers are reading accurate values',
          ),
        ];
        
        // Add items to category
        await _updateCategoryChecklists(terCategory, ChecklistFrequency.daily, terDailyItems);
        await _updateCategoryChecklists(terCategory, ChecklistFrequency.weekly, terWeeklyItems);
        await _updateCategoryChecklists(terCategory, ChecklistFrequency.monthly, terMonthlyItems);
      }
      
      debugPrint('Added injection moulding checklists for equipment $equipmentId');
    } catch (e) {
      _error = 'Error adding injection moulding checklists: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }
  
  // Helper to update category checklists
  Future<void> _updateCategoryChecklists(
    MaintenanceCategory category,
    ChecklistFrequency frequency,
    List<ChecklistItem> items
  ) async {
    // Create updated checklists map
    final updatedChecklists = Map<ChecklistFrequency, List<ChecklistItem>>.from(category.checklists);
    
    // Add new items, preserving any existing ones
    if (updatedChecklists.containsKey(frequency)) {
      // Filter out duplicate descriptions
      final existingDescriptions = updatedChecklists[frequency]!.map((e) => e.description).toSet();
      final newItems = items.where((item) => !existingDescriptions.contains(item.description)).toList();
      
      updatedChecklists[frequency] = [
        ...updatedChecklists[frequency]!,
        ...newItems
      ];
    } else {
      updatedChecklists[frequency] = items;
    }
    
    // Create updated category
    final updatedCategory = MaintenanceCategory(
      id: category.id,
      equipmentId: category.equipmentId,
      type: category.type,
      checklists: updatedChecklists,
    );
    
    // Update the category
    await addOrUpdateMaintenanceCategory(updatedCategory);
  }
  
  // Reload all data (for use with reset functionality)
  Future<void> reloadData() async {
    debugPrint('Reloading equipment data...');
    
    // Clear current data
    _equipmentList = [];
    _maintenanceCategories = [];
    notifyListeners();
    
    // Reload data from storage (or add sample data if none exists)
    await _loadData();
    
    // Make sure there are no duplicate categories
    await removeDuplicateCategories();
    
    // Notify listeners that data has been reloaded
    notifyListeners();
    
    debugPrint('Equipment data reloaded');
  }

  // Remove duplicate maintenance categories for all equipment
  Future<void> removeDuplicateCategories() async {
    _setLoading(true);
    try {
      debugPrint('Checking for duplicate maintenance categories...');
      bool duplicatesFound = false;
      
      // Group categories by equipment ID
      final Map<String, List<MaintenanceCategory>> categoriesByEquipment = {};
      
      for (var category in _maintenanceCategories) {
        if (!categoriesByEquipment.containsKey(category.equipmentId)) {
          categoriesByEquipment[category.equipmentId] = [];
        }
        categoriesByEquipment[category.equipmentId]!.add(category);
      }
      
      // Check each equipment for duplicates
      for (var equipmentId in categoriesByEquipment.keys) {
        final categories = categoriesByEquipment[equipmentId]!;
        
        // Group categories by type
        final Map<MaintenanceCategoryType, List<MaintenanceCategory>> categoriesByType = {};
        
        for (var category in categories) {
          if (!categoriesByType.containsKey(category.type)) {
            categoriesByType[category.type] = [];
          }
          categoriesByType[category.type]!.add(category);
        }
        
        // Check for duplicates
        List<MaintenanceCategory> categoriesToRemove = [];
        
        for (var type in categoriesByType.keys) {
          if (categoriesByType[type]!.length > 1) {
            // Keep the first one (with non-empty checklists if possible)
            final typedCategories = categoriesByType[type]!;
            
            // Sort by ID to ensure consistent results
            typedCategories.sort((a, b) => a.id.compareTo(b.id));
            
            // Try to find a category with checklists
            var categoryToKeep = typedCategories.firstWhere(
              (c) => c.checklists.values.any((items) => items.isNotEmpty),
              orElse: () => typedCategories.first,
            );
            
            // Mark others for removal
            for (var category in typedCategories) {
              if (category.id != categoryToKeep.id) {
                categoriesToRemove.add(category);
                duplicatesFound = true;
                debugPrint('Found duplicate category to remove: ${category.id} (type: ${category.type})');
              }
            }
          }
        }
        
        // Remove duplicates
        if (categoriesToRemove.isNotEmpty) {
          _maintenanceCategories.removeWhere((c) => 
            categoriesToRemove.any((toRemove) => toRemove.id == c.id)
          );
          debugPrint('Removed ${categoriesToRemove.length} duplicate categories for equipment $equipmentId');
        }
      }
      
      if (duplicatesFound) {
        await _saveData();
        debugPrint('Saved data after removing duplicate categories');
      } else {
        debugPrint('No duplicate categories found');
      }
    } catch (e) {
      _error = 'Error removing duplicate categories: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }
} 