import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/maintenance_category.dart';
import '../models/checklist_item.dart';
import '../providers/equipment_provider.dart';
import 'checklist_screen.dart';
import 'machine_checklist_screen.dart';

class CategoryListScreen extends StatelessWidget {
  final String equipmentId;

  const CategoryListScreen({super.key, required this.equipmentId});

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final equipment = equipmentProvider.getEquipmentById(equipmentId);

    if (equipment == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Equipment Not Found'),
        ),
        body: const Center(
          child: Text('The requested equipment could not be found.'),
        ),
      );
    }

    final categories = equipmentProvider.getCategoriesForEquipment(equipmentId);

    return Scaffold(
      appBar: AppBar(
        title: Text('${equipment.name} - Maintenance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(equipment.name, equipment.location),
            const SizedBox(height: 8),
            if (equipment.machineType != 'General') ...[
              _buildMachineTypeCard(context, equipment.machineType),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            const Text(
              'Maintenance Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildCategoryList(context, categories),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String equipmentName, String location) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              equipmentName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Location: $location',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMachineTypeCard(BuildContext context, String machineType) {
    return Card(
      elevation: 3,
      color: Colors.blue.shade50,
      child: InkWell(
        onTap: () => _navigateToMachineChecklistScreen(context, machineType),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      machineType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Machine-Specific Checklists',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.engineering),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Specialized maintenance tasks for this machine type',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, List<MaintenanceCategory> categories) {
    if (categories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No maintenance categories',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(context, category);
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, MaintenanceCategory category) {
    final cardColor = _getCategoryColor(category.type);
    final totalItems = _getTotalChecklistItems(category);
    final completedItems = _getCompletedChecklistItems(category);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToChecklistScreen(context, category),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      category.type.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.type.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Checklist Items: $completedItems / $totalItems',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              if (totalItems > 0) ...[
                LinearProgressIndicator(
                  value: totalItems > 0 ? completedItems / totalItems : 0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                ),
              ],
              const SizedBox(height: 16),
              _buildFrequencyChips(category),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyChips(MaintenanceCategory category) {
    final frequencies = category.checklists.keys.toList();
    frequencies.sort((a, b) => a.index.compareTo(b.index));

    if (frequencies.isEmpty) {
      return const Text(
        'No checklists available',
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }

    return Wrap(
      spacing: 8,
      children: frequencies.map((frequency) {
        final itemCount = category.checklists[frequency]?.length ?? 0;
        return Chip(
          label: Text('${frequency.displayName} ($itemCount)'),
          backgroundColor: Colors.grey[200],
        );
      }).toList(),
    );
  }

  void _navigateToChecklistScreen(BuildContext context, MaintenanceCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChecklistScreen(
          equipmentId: equipmentId,
          category: category.type.code,
        ),
      ),
    );
  }

  void _navigateToMachineChecklistScreen(BuildContext context, String machineType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MachineChecklistScreen(
          equipmentId: equipmentId,
          machineType: machineType,
        ),
      ),
    );
  }

  Color _getCategoryColor(MaintenanceCategoryType type) {
    switch (type) {
      case MaintenanceCategoryType.inspectionMaintenance:
        return Colors.blue;
      case MaintenanceCategoryType.basicTasks:
        return Colors.green;
      case MaintenanceCategoryType.technicalEquipmentReview:
        return Colors.orange;
    }
  }

  int _getTotalChecklistItems(MaintenanceCategory category) {
    int total = 0;
    category.checklists.forEach((_, items) {
      total += items.length;
    });
    return total;
  }

  int _getCompletedChecklistItems(MaintenanceCategory category) {
    int completed = 0;
    category.checklists.forEach((_, items) {
      completed += items.where((item) => item.isCompleted).length;
    });
    return completed;
  }
} 