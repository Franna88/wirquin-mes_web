import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../models/checklist_item.dart';
import '../providers/checklist_provider.dart';
import '../providers/equipment_provider.dart';
import 'package:intl/intl.dart';

class MachineChecklistScreen extends StatelessWidget {
  final String equipmentId;
  final String machineType;

  const MachineChecklistScreen({
    super.key, 
    required this.equipmentId, 
    required this.machineType,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: ChecklistFrequency.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('$machineType Checklists'),
          bottom: TabBar(
            isScrollable: true,
            tabs: ChecklistFrequency.values.map((frequency) {
              return Tab(text: frequency.displayName);
            }).toList(),
          ),
        ),
        body: TabBarView(
          children: ChecklistFrequency.values.map((frequency) {
            return _ChecklistTabContent(
              equipmentId: equipmentId,
              machineType: machineType,
              frequency: frequency,
            );
          }).toList(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addChecklistItem(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _addChecklistItem(BuildContext context) {
    final tabController = DefaultTabController.of(context);
    final currentFrequency = ChecklistFrequency.values[tabController.index];
    
    showDialog(
      context: context,
      builder: (context) => _ChecklistItemDialog(
        equipmentId: equipmentId,
        category: 'BT', // Using BT for machine-specific checklists
        frequency: currentFrequency,
        machineType: machineType,
      ),
    );
  }
}

class _ChecklistTabContent extends StatelessWidget {
  final String equipmentId;
  final String machineType;
  final ChecklistFrequency frequency;

  const _ChecklistTabContent({
    required this.equipmentId,
    required this.machineType,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final equipment = equipmentProvider.getEquipmentById(equipmentId);
    
    if (equipment == null) {
      return const Center(child: Text('Equipment not found'));
    }

    // Get all BT items for this frequency as they're machine-specific
    final items = checklistProvider.getItemsForCategoryAndFrequency(
      equipmentId,
      'BT',
      frequency,
    ).where((item) => item.notes?.contains(machineType) ?? false).toList();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.engineering,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${frequency.displayName} checklist items for $machineType',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add items using the + button',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Group by day of week (or date for less frequent items)
    final groupedItems = _groupItems(items);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedItems.length,
      itemBuilder: (context, groupIndex) {
        final groupKey = groupedItems.keys.elementAt(groupIndex);
        final groupItems = groupedItems[groupKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                groupKey,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...groupItems.map((item) => _buildChecklistItemCard(context, item)),
            const Divider(thickness: 2),
          ],
        );
      },
    );
  }

  Map<String, List<ChecklistItem>> _groupItems(List<ChecklistItem> items) {
    final now = DateTime.now();
    final Map<String, List<ChecklistItem>> grouped = {};
    
    switch (frequency) {
      case ChecklistFrequency.daily:
        // Group by days of the week
        final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        
        for (final day in days) {
          grouped[day] = [];
        }
        
        for (final item in items) {
          // If item was completed this week, add it to the specific day
          if (item.lastCompletedDate != null) {
            final completedDay = DateFormat('EEEE').format(item.lastCompletedDate!);
            grouped[completedDay]?.add(item);
          } else {
            // Otherwise, add to today's items
            final today = DateFormat('EEEE').format(now);
            grouped[today]?.add(item);
          }
        }
        break;
        
      case ChecklistFrequency.weekly:
        // Group by week number
        final formatter = DateFormat("'Week' w");
        final thisWeek = formatter.format(now);
        grouped[thisWeek] = items;
        break;
        
      case ChecklistFrequency.monthly:
        // Group by month
        final formatter = DateFormat('MMMM yyyy');
        final thisMonth = formatter.format(now);
        grouped[thisMonth] = items;
        break;
        
      case ChecklistFrequency.quarterly:
        // Group by quarter
        final quarter = (now.month - 1) ~/ 3 + 1;
        final quarterLabel = 'Q$quarter ${now.year}';
        grouped[quarterLabel] = items;
        break;
        
      case ChecklistFrequency.yearly:
        // Check if items are 6-monthly or yearly
        grouped['Yearly'] = items.where((item) => 
          !(item.notes?.contains('6-Monthly') ?? false)).toList();
        
        grouped['6-Monthly'] = items.where((item) => 
          item.notes?.contains('6-Monthly') ?? false).toList();
        break;
    }
    
    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);
    
    return grouped;
  }

  Widget _buildChecklistItemCard(BuildContext context, ChecklistItem item) {
    final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.description),
        subtitle: item.lastCompletedDate != null 
          ? Text('Last completed: ${DateFormat('MMM d, yyyy').format(item.lastCompletedDate!)}')
          : null,
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (value) {
            if (value != null) {
              checklistProvider.toggleItemCompletion(item.id, value);
            }
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.result.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getResultColor(item.result),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.result,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            if (item.photoUrl != null && item.photoUrl!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.photo, color: Colors.blue),
                onPressed: () => _showPhotoDialog(context, item),
                tooltip: 'View Photo',
              ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editChecklistItem(context, item),
            ),
          ],
        ),
        onTap: () => _showResultEditor(context, item),
      ),
    );
  }

  void _editChecklistItem(BuildContext context, ChecklistItem item) {
    showDialog(
      context: context,
      builder: (context) => _ChecklistItemDialog(
        equipmentId: equipmentId,
        category: 'BT',
        frequency: frequency,
        existingItem: item,
        machineType: machineType,
      ),
    );
  }

  void _showResultEditor(BuildContext context, ChecklistItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.description,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Set Result:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildResultButton(context, item, 'YES'),
                  _buildResultButton(context, item, 'NO'),
                  _buildResultButton(context, item, 'GOOD'),
                  _buildResultButton(context, item, 'DONE'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Custom Result (e.g., numerical value)',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: item.result),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _updateItemResult(context, item, value);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Photo button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _capturePhoto(context, item);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Photo'),
                  ),
                ],
              ),
              
              // Display photo if available
              if (item.photoUrl != null && item.photoUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildPhotoThumbnail(context, item),
              ],
              
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Comments on the issue',
                  border: OutlineInputBorder(),
                  hintText: 'Add detailed notes about this item',
                ),
                controller: TextEditingController(text: item.notes ?? ''),
                maxLines: 3,
                onChanged: (value) {
                  final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
                  final updatedItem = item.copyWith(notes: value);
                  checklistProvider.updateItem(updatedItem);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultButton(BuildContext context, ChecklistItem item, String resultText) {
    final isSelected = item.result == resultText;
    return ElevatedButton(
      onPressed: () {
        _updateItemResult(context, item, resultText);
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? _getResultColor(resultText) : null,
        foregroundColor: isSelected ? Colors.white : null,
      ),
      child: Text(resultText),
    );
  }

  void _updateItemResult(BuildContext context, ChecklistItem item, String result) {
    final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
    final updatedItem = item.copyWith(
      result: result,
      isCompleted: true,
      lastCompletedDate: DateTime.now(),
    );
    checklistProvider.updateItem(updatedItem);
  }

  Color _getResultColor(String result) {
    switch (result.toUpperCase()) {
      case 'YES':
        return Colors.green;
      case 'NO':
        return Colors.red;
      case 'GOOD':
        return Colors.blue;
      case 'DONE':
        return Colors.purple;
      case 'BAD':
        return Colors.orange;
      default:
        // For numerical values or custom text
        return Colors.grey.shade700;
    }
  }

  Widget _buildPhotoThumbnail(BuildContext context, ChecklistItem item) {
    if (item.photoUrl == null || item.photoUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _showPhotoDialog(context, item);
      },
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.photoUrl!.startsWith('data:image')
              ? Image.memory(
                  base64Decode(item.photoUrl!.split(',').last),
                  fit: BoxFit.cover,
                )
              : Image.file(
                  File(item.photoUrl!),
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }

  // Show full-size photo in dialog
  void _showPhotoDialog(BuildContext context, ChecklistItem item) {
    if (item.photoUrl == null || item.photoUrl!.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(item.description),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (item.photoUrl!.startsWith('data:image'))
                        Image.memory(
                          base64Decode(item.photoUrl!.split(',').last),
                          fit: BoxFit.contain,
                        )
                      else
                        Image.file(
                          File(item.photoUrl!),
                          fit: BoxFit.contain,
                        ),
                      const SizedBox(height: 16),
                      if (item.result.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getResultColor(item.result),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Result: ${item.result}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        Text(
                          'Notes: ${item.notes}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      _capturePhoto(context, item);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Replace'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final checklistProvider = 
                          Provider.of<ChecklistProvider>(context, listen: false);
                      final updatedItem = item.copyWith(photoUrl: null);
                      checklistProvider.updateItem(updatedItem);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Capture a new photo
  Future<void> _capturePhoto(BuildContext context, ChecklistItem item) async {
    final ImagePicker picker = ImagePicker();
    final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
    
    try {
      // Show options to choose camera or gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      if (source == null) return;
      
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        // For web, we need to store as data URL
        if (pickedFile.path.startsWith('http') || pickedFile.path.startsWith('blob')) {
          final bytes = await pickedFile.readAsBytes();
          final base64Image = base64Encode(bytes);
          final dataUrl = 'data:image/jpeg;base64,$base64Image';
          
          final updatedItem = item.copyWith(
            photoUrl: dataUrl,
            isCompleted: true,
            lastCompletedDate: DateTime.now(),
          );
          
          checklistProvider.updateItem(updatedItem);
        } else {
          // For mobile, we can store the file path
          final updatedItem = item.copyWith(
            photoUrl: pickedFile.path,
            isCompleted: true,
            lastCompletedDate: DateTime.now(),
          );
          
          checklistProvider.updateItem(updatedItem);
        }
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing photo: $e')),
      );
    }
  }
}

class _ChecklistItemDialog extends StatefulWidget {
  final String equipmentId;
  final String category;
  final ChecklistFrequency frequency;
  final ChecklistItem? existingItem;
  final String machineType;

  const _ChecklistItemDialog({
    required this.equipmentId,
    required this.category,
    required this.frequency,
    this.existingItem,
    required this.machineType,
  });

  @override
  State<_ChecklistItemDialog> createState() => _ChecklistItemDialogState();
}

class _ChecklistItemDialogState extends State<_ChecklistItemDialog> {
  late ChecklistFrequency _frequency;
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _resultController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _frequency = widget.frequency;
    
    if (widget.existingItem != null) {
      _descriptionController.text = widget.existingItem!.description;
      if (widget.existingItem!.notes != null) {
        _notesController.text = widget.existingItem!.notes!;
      }
      _resultController.text = widget.existingItem!.result;
    } else {
      // For new items, pre-fill the notes with machine type
      _notesController.text = '${widget.machineType} Machine';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingItem != null 
        ? 'Edit Checklist Item' 
        : 'Add Checklist Item'
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<ChecklistFrequency>(
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                ),
                value: _frequency,
                items: ChecklistFrequency.values.map((frequency) {
                  return DropdownMenuItem(
                    value: frequency,
                    child: Text(frequency.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _frequency = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _resultController,
                decoration: const InputDecoration(
                  labelText: 'Result (e.g., YES, NO, GOOD, DONE, or numerical value)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveChecklistItem,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveChecklistItem() {
    if (_formKey.currentState!.validate()) {
      final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
      
      if (widget.existingItem != null) {
        // Update existing item
        final updatedItem = widget.existingItem!.copyWith(
          frequency: _frequency,
          description: _descriptionController.text,
          notes: _notesController.text,
          result: _resultController.text,
        );
        checklistProvider.updateItem(updatedItem);
      } else {
        // Add new item
        final newItem = ChecklistItem(
          equipmentId: widget.equipmentId,
          categoryName: widget.category,
          frequency: _frequency,
          description: _descriptionController.text,
          notes: _notesController.text,
          result: _resultController.text,
        );
        checklistProvider.addItem(newItem);
      }
      
      Navigator.of(context).pop();
    }
  }
} 