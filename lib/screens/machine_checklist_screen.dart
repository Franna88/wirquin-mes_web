import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/checklist_item.dart';
import '../providers/checklist_provider.dart';
import '../providers/equipment_provider.dart';
import '../data/machine_checklists.dart';

class MachineChecklistScreen extends StatefulWidget {
  final String equipmentId;
  final String machineType;

  const MachineChecklistScreen({
    super.key,
    required this.equipmentId,
    required this.machineType,
  });

  @override
  State<MachineChecklistScreen> createState() => _MachineChecklistScreenState();
}

class _MachineChecklistScreenState extends State<MachineChecklistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<ChecklistFrequency> _frequencies = [
    ChecklistFrequency.daily,
    ChecklistFrequency.weekly,
    ChecklistFrequency.monthly,
    ChecklistFrequency.quarterly,
    ChecklistFrequency.yearly,
  ];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _frequencies.length, vsync: this);
    
    // Initialize the checklists after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChecklists();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeChecklists() async {
    final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
    final equipment = Provider.of<EquipmentProvider>(context, listen: false)
        .getEquipmentById(widget.equipmentId);
    
    if (equipment == null) return;
    
    // Check if checklists are already created for this equipment/machine type
    final existingItems = checklistProvider.getChecklistItemsForEquipment(widget.equipmentId)
        .where((item) => item.categoryName == widget.machineType)
        .toList();
    
    if (existingItems.isEmpty) {
      // Create checklists for each frequency
      for (var frequency in _frequencies) {
        final items = MachineChecklists.createChecklistItems(
          equipmentId: widget.equipmentId,
          machineType: widget.machineType,
          frequency: frequency,
        );
        
        // Add each item
        for (var item in items) {
          await checklistProvider.addItem(item);
        }
      }
    }
    
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final equipment = equipmentProvider.getEquipmentById(widget.equipmentId);

    if (equipment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Equipment Not Found')),
        body: const Center(child: Text('The requested equipment could not be found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${equipment.name} - ${widget.machineType} Checklists'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _frequencies.map((frequency) {
            return Tab(text: frequency.displayName);
          }).toList(),
        ),
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _frequencies.map((frequency) {
                return _buildChecklistTab(frequency);
              }).toList(),
            ),
    );
  }

  Widget _buildChecklistTab(ChecklistFrequency frequency) {
    return Consumer<ChecklistProvider>(
      builder: (context, checklistProvider, _) {
        final items = checklistProvider.getItemsForCategoryAndFrequency(
          widget.equipmentId,
          widget.machineType,
          frequency,
        );

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.checklist, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No ${frequency.displayName} checklist items found',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final newItems = MachineChecklists.createChecklistItems(
                      equipmentId: widget.equipmentId,
                      machineType: widget.machineType,
                      frequency: frequency,
                    );
                    
                    for (var item in newItems) {
                      await checklistProvider.addItem(item);
                    }
                  },
                  child: const Text('Create Checklist Items'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildChecklistItem(context, item);
          },
        );
      },
    );
  }

  Widget _buildChecklistItem(BuildContext context, ChecklistItem item) {
    final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
    final machineType = widget.machineType;

    // Find example value from the template
    final frequencyString = MachineChecklists.getStringFromFrequency(item.frequency);
    final templates = MachineChecklists.templates[machineType]?[frequencyString] ?? [];
    final template = templates.firstWhere(
      (t) => t['description'] == item.description,
      orElse: () => {'description': '', 'example': ''},
    );
    final example = template['example'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.description,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (example.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Example: $example',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.result,
                    decoration: const InputDecoration(
                      labelText: 'Result',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Update the result
                      final updatedItem = item.copyWith(result: value);
                      checklistProvider.updateChecklistItem(updatedItem);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Checkbox(
                  value: item.isCompleted,
                  onChanged: (value) {
                    // Update completion status
                    final updatedItem = item.copyWith(
                      isCompleted: value ?? false,
                      lastCompletedDate: (value ?? false) ? DateTime.now() : null,
                    );
                    checklistProvider.updateChecklistItem(updatedItem);
                  },
                ),
                const Text('Completed'),
              ],
            ),
            if (item.lastCompletedDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last completed: ${item.lastCompletedDate!.toLocal().toString().split('.')[0]}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${item.notes}',
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Show dialog to add notes
                _showAddNotesDialog(context, item);
              },
              child: const Text('Add Notes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNotesDialog(BuildContext context, ChecklistItem item) {
    final notesController = TextEditingController(text: item.notes);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Notes'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'Enter notes here...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
              final updatedItem = item.copyWith(notes: notesController.text);
              checklistProvider.updateChecklistItem(updatedItem);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
} 