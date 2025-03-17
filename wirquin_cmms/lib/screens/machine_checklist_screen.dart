import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../models/checklist_item.dart';
import '../providers/checklist_provider.dart';
import '../providers/equipment_provider.dart';
import 'package:intl/intl.dart';
import '../data/machine_checklists.dart';

class MachineChecklistScreen extends StatefulWidget {
  final String equipmentId;
  final String machineType; // Currently selected checklist type (IM, BT, TER)

  const MachineChecklistScreen({
    Key? key,
    required this.equipmentId,
    required this.machineType, 
  }) : super(key: key);

  @override
  State<MachineChecklistScreen> createState() => _MachineChecklistScreenState();
}

class _MachineChecklistScreenState extends State<MachineChecklistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<ChecklistFrequency, List<ChecklistItem>> frequencyItems = {};
  bool isLoading = true;
  String _selectedType = ''; // Current checklist type (IM, BT, TER)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _selectedType = widget.machineType;
    _loadChecklists();
  }

  @override
  void didUpdateWidget(MachineChecklistScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.machineType != widget.machineType) {
      setState(() {
        _selectedType = widget.machineType;
      });
      _loadChecklists();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChecklists() async {
    setState(() {
      isLoading = true;
    });

    print('🔍 Loading checklists for equipment: ${widget.equipmentId}, type: ${_selectedType}');

    // Initialize frequencies
    frequencyItems = {
      ChecklistFrequency.daily: [],
      ChecklistFrequency.weekly: [],
      ChecklistFrequency.monthly: [],
      ChecklistFrequency.quarterly: [],
      ChecklistFrequency.yearly: [],
    };

    // Get the checklist provider
    final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
    
    // First, ensure checklists are created for this equipment/machine type
    print('Creating machine checklists for ${_selectedType}');
    await checklistProvider.createMachineChecklists(widget.equipmentId, _selectedType);
    print('Finished creating machine checklists');
    
    // Load all frequencies
    final frequencies = [
      ChecklistFrequency.daily,
      ChecklistFrequency.weekly, 
      ChecklistFrequency.monthly,
      ChecklistFrequency.quarterly,
      ChecklistFrequency.yearly,
    ];

    for (var frequency in frequencies) {
      print('Loading ${frequency.toString()} checklists');
      final items = checklistProvider.getMachineChecklistItems(
        widget.equipmentId, 
        _selectedType,
        frequency,
      );
      
      print('Found ${items.length} ${frequency.toString()} checklist items');
      
      // Add all items to the appropriate frequency list
      for (var item in items) {
        if (frequencyItems.containsKey(item.frequency)) {
          frequencyItems[item.frequency]!.add(item);
        }
      }
    }

    // Print summary
    print('📊 Checklist summary:');
    frequencyItems.forEach((frequency, items) {
      print('${frequency.toString()}: ${items.length} items');
    });

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_selectedType} Checklists'),
        actions: [
          // Add dropdown to switch between checklist types
          DropdownButton<String>(
            value: _selectedType,
            dropdownColor: Theme.of(context).primaryColor,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            underline: Container(height: 0),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedType = newValue;
                });
                _loadChecklists();
              }
            },
            items: ['IM', 'BT', 'TER']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'Quarterly'),
            Tab(text: 'Yearly'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChecklistTab(ChecklistFrequency.daily),
                _buildChecklistTab(ChecklistFrequency.weekly),
                _buildChecklistTab(ChecklistFrequency.monthly),
                _buildChecklistTab(ChecklistFrequency.quarterly),
                _buildChecklistTab(ChecklistFrequency.yearly),
              ],
            ),
    );
  }

  Widget _buildChecklistTab(ChecklistFrequency frequency) {
    final items = frequencyItems[frequency] ?? [];

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No checklist items found for this frequency'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                // Generate items for this frequency specifically
                final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
                final newItems = MachineChecklists.createChecklistItems(
                  equipmentId: widget.equipmentId,
                  machineType: _selectedType,
                  frequency: frequency,
                );
                
                // Add items to provider
                for (var item in newItems) {
                  await checklistProvider.addItem(item);
                }
                
                // Reload checklists
                _loadChecklists();
                
                // Show success message
                if (context.mounted && newItems.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Generated ${newItems.length} checklist items!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_circle),
              label: const Text('Generate Checklist Items'),
            ),
          ],
        ),
      );
    }
    
    // If items exist, show them
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildChecklistItem(item);
      },
    );
  }

  Widget _buildChecklistItem(ChecklistItem item) {
    return Card(
      margin: const EdgeInsets.all(8.0),
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
                    item.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (item.lastCompletedDate != null)
                  Text(
                    'Last: ${_formatDate(item.lastCompletedDate!)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Result input field - could be text or checkbox depending on the type
                Expanded(
                  child: TextFormField(
                    initialValue: item.result,
                    decoration: InputDecoration(
                      labelText: 'Result',
                      hintText: 'Example: ${_getExampleForDescription(item.description)}',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
                      
                      // Update the result
                      final updatedItem = item.copyWith(result: value);
                      checklistProvider.updateItem(updatedItem);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Completed checkbox
                Row(
                  children: [
                    const Text('Completed:'),
                    Checkbox(
                      value: item.isCompleted,
                      onChanged: (value) {
                        final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
                        final updatedItem = item.copyWith(
                          isCompleted: value ?? false,
                          lastCompletedDate: (value ?? false) ? DateTime.now() : null,
                        );
                        checklistProvider.updateItem(updatedItem);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.note),
              label: const Text('Add Notes'),
              onPressed: () => _showNotesDialog(context, item),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                foregroundColor: Colors.blue[900],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getExampleForDescription(String description) {
    // Look up example from templates
    for (var frequencyMap in MachineChecklists.templates[_selectedType]!.values) {
      for (var item in frequencyMap) {
        if (item['description'] == description) {
          return item['example'] ?? '';
        }
      }
    }
    return '';
  }

  void _showNotesDialog(BuildContext context, ChecklistItem item) {
    final notesController = TextEditingController(text: item.notes);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notes'),
        content: TextField(
          controller: notesController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter notes about this checklist item',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
              final updatedItem = item.copyWith(notes: notesController.text);
              checklistProvider.updateItem(updatedItem);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
} 