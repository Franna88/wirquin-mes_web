import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/equipment_provider.dart';
import '../models/equipment.dart';
import 'equipment_detail_screen.dart';
import 'category_list_screen.dart';

class EquipmentListScreen extends StatelessWidget {
  const EquipmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment List'),
      ),
      body: Consumer<EquipmentProvider>(
        builder: (ctx, equipmentProvider, _) {
          if (equipmentProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (equipmentProvider.error.isNotEmpty) {
            return Center(
              child: Text(
                'Error: ${equipmentProvider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final equipmentList = equipmentProvider.equipmentList;

          if (equipmentList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.engineering_outlined,
                    size: 100,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No equipment found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Add your first equipment to get started with maintenance tracking',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddEquipment(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Equipment'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: equipmentList.length,
            itemBuilder: (ctx, index) {
              final equipment = equipmentList[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _navigateToCategories(context, equipment.id),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                equipment.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildStatusChip(equipment.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (equipment.location.isNotEmpty) ...[
                          Text('Location: ${equipment.location}'),
                          const SizedBox(height: 4),
                        ],
                        if (equipment.model.isNotEmpty) ...[
                          Text('Model: ${equipment.model}'),
                          const SizedBox(height: 4),
                        ],
                        if (equipment.lastMaintenanceDate.isNotEmpty) ...[
                          Text('Last Maintenance: ${equipment.lastMaintenanceDate}'),
                          const SizedBox(height: 4),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Maintenance Categories: ${equipmentProvider.getCategoriesForEquipment(equipment.id).length}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                _navigateToCategories(context, equipment.id);
                              },
                              icon: const Icon(Icons.checklist),
                              label: const Text('Maintenance'),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                _navigateToEditEquipment(context, equipment);
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                _showDeleteConfirmation(context, equipment);
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEquipment(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'operational':
        color = Colors.green;
        label = 'Operational';
        break;
      case 'maintenance':
        color = Colors.orange;
        label = 'Maintenance';
        break;
      case 'out of service':
        color = Colors.red;
        label = 'Out of Service';
        break;
      case 'standby':
        color = Colors.blue;
        label = 'Standby';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _navigateToAddEquipment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EquipmentDetailScreen(),
      ),
    );
  }

  void _navigateToCategories(BuildContext context, String equipmentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryListScreen(equipmentId: equipmentId),
      ),
    );
  }

  void _navigateToEditEquipment(BuildContext context, Equipment equipment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipmentDetailScreen(equipment: equipment),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Equipment equipment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Equipment'),
        content: Text(
          'Are you sure you want to delete ${equipment.name}? '
          'This will also delete all associated maintenance data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final equipmentProvider = Provider.of<EquipmentProvider>(
                context,
                listen: false,
              );
              equipmentProvider.deleteEquipment(equipment.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 