import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/checklist_provider.dart';
import '../models/equipment.dart';
import '../models/checklist_item.dart';

class OEEDashboardScreen extends StatelessWidget {
  const OEEDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Ensure we can access both providers
        ChangeNotifierProvider.value(value: Provider.of<EquipmentProvider>(context, listen: false)),
        ChangeNotifierProvider.value(value: Provider.of<ChecklistProvider>(context, listen: false)),
      ],
      child: Consumer2<EquipmentProvider, ChecklistProvider>(
        builder: (context, equipmentProvider, checklistProvider, child) {
          if (equipmentProvider.isLoading || checklistProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Get all equipment items
          final allEquipment = equipmentProvider.equipmentList;
          
          // Group equipment by status
          final operationalMachines = allEquipment.where((e) => e.status == 'Operational').toList();
          final offlineMachines = allEquipment.where((e) => e.status == 'Offline').toList();
          final maintenanceMachines = allEquipment.where((e) => e.status == 'Under Maintenance').toList();
          
          // Get checklist items
          final allChecklistItems = _getAllChecklistItems(checklistProvider);
          
          // Get machines needing daily checks in each category
          final imDailyChecksMachines = _getMachinesNeedingCategoryChecks(
            allEquipment, 
            allChecklistItems, 
            'IM', 
            ChecklistFrequency.daily
          );
          
          final btDailyChecksMachines = _getMachinesNeedingCategoryChecks(
            allEquipment, 
            allChecklistItems, 
            'BT', 
            ChecklistFrequency.daily
          );
          
          final terDailyChecksMachines = _getMachinesNeedingCategoryChecks(
            allEquipment, 
            allChecklistItems, 
            'TER', 
            ChecklistFrequency.daily
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop,
                              color: Color(0xFFE32118),
                              size: 28,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE32118),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Wirquin Machine Status Overview',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Machine Status section
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          'Operational',
                          operationalMachines.length.toString(),
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatusCard(
                          'Offline',
                          offlineMachines.length.toString(),
                          Colors.red.shade700,
                          Icons.cancel,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatusCard(
                          'Maintenance',
                          maintenanceMachines.length.toString(),
                          Colors.orange,
                          Icons.build,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Daily Checks Needed section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.checklist,
                              color: Color(0xFFE32118),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Daily Checks Needed',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE32118),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // IM Daily Checks
                        _buildChecksCard(
                          'IM Daily Checks',
                          imDailyChecksMachines,
                          Icons.engineering,
                          Color(0xFF1976D2),
                        ),
                        const SizedBox(height: 16),
                        
                        // BT Daily Checks
                        _buildChecksCard(
                          'BT Daily Checks',
                          btDailyChecksMachines,
                          Icons.handyman,
                          Color(0xFF388E3C),
                        ),
                        const SizedBox(height: 16),
                        
                        // TER Daily Checks
                        _buildChecksCard(
                          'TER Daily Checks',
                          terDailyChecksMachines,
                          Icons.precision_manufacturing,
                          Color(0xFFE64A19),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Machine Lists section
                  if (offlineMachines.isNotEmpty) ...[
                    _buildMachineList(
                      'Offline Machines',
                      offlineMachines,
                      Icons.cancel,
                      Colors.red.shade700,
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  if (maintenanceMachines.isNotEmpty) ...[
                    _buildMachineList(
                      'Machines Under Maintenance',
                      maintenanceMachines,
                      Icons.build,
                      Colors.orange,
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  _buildMachineList(
                    'All Machines',
                    allEquipment,
                    Icons.precision_manufacturing,
                    Color(0xFFE32118),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Helper to get all checklist items
  List<ChecklistItem> _getAllChecklistItems(ChecklistProvider provider) {
    // Use the new method added to ChecklistProvider
    return provider.getAllItems();
  }
  
  // Helper to get machines needing checks for a specific category and frequency
  List<Equipment> _getMachinesNeedingCategoryChecks(
    List<Equipment> equipment,
    List<ChecklistItem> checklistItems,
    String categoryCode,
    ChecklistFrequency frequency
  ) {
    final Set<String> equipmentIds = {};
    
    // Find equipment IDs with incomplete checklist items
    for (var item in checklistItems) {
      if (item.categoryName == categoryCode && 
          item.frequency == frequency && 
          !item.isCompleted) {
        equipmentIds.add(item.equipmentId);
      }
    }
    
    // Get the equipment objects
    return equipment.where((e) => equipmentIds.contains(e.id)).toList();
  }

  Widget _buildStatusCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE32118),
                  ),
                ),
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChecksCard(String title, List<Equipment> machines, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                SizedBox(width: 8),
                Text(
                  '$title: ${machines.length} Machines',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            if (machines.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: machines.length > 3 ? 3 : machines.length,
                itemBuilder: (context, index) {
                  final machine = machines[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.water_drop, color: color),
                    title: Text(
                      machine.name,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(machine.location),
                  );
                },
              ),
              if (machines.length > 3) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      // Show all machines in this category
                    },
                    icon: Icon(Icons.arrow_forward, size: 16),
                    label: Text('See all ${machines.length}'),
                    style: TextButton.styleFrom(
                      foregroundColor: color,
                    ),
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'No machines need checks',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildMachineList(String title, List<Equipment> machines, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
              ),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Spacer(),
              Text(
                '${machines.length} machines',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (machines.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'No machines in this category',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: machines.length,
              itemBuilder: (context, index) {
                final machine = machines[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  elevation: 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(
                        _getMachineIcon(machine.machineType),
                        color: color,
                      ),
                    ),
                    title: Text(
                      machine.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${machine.machineType} • ${machine.location}',
                    ),
                    trailing: _getStatusIndicator(machine.status),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _getStatusIndicator(String status) {
    IconData icon;
    Color color;
    
    switch (status) {
      case 'Operational':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'Offline':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case 'Under Maintenance':
        icon = Icons.build;
        color = Colors.orange;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }
    
    return Icon(icon, color: color);
  }
  
  IconData _getMachineIcon(String machineType) {
    switch (machineType.toLowerCase()) {
      case 'injection moulding':
        return Icons.water_drop;
      case 'extruder':
        return Icons.settings_input_component;
      case 'cnc':
        return Icons.precision_manufacturing;
      case 'packaging':
        return Icons.inventory_2;
      default:
        return Icons.factory;
    }
  }
} 