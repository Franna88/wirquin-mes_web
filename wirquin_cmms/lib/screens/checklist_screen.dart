import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../models/checklist_item.dart';
import '../providers/checklist_provider.dart';
import '../providers/equipment_provider.dart';

class ChecklistScreen extends StatelessWidget {
  final String equipmentId;
  final String category;

  const ChecklistScreen({
    super.key, 
    required this.equipmentId, 
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$category Checklist'),
      ),
      body: _ChecklistContent(equipmentId: equipmentId, category: category),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addChecklistItem(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addChecklistItem(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ChecklistItemDialog(
        equipmentId: equipmentId,
        category: category,
      ),
    );
  }
}

class _ChecklistContent extends StatefulWidget {
  final String equipmentId;
  final String category;

  const _ChecklistContent({
    required this.equipmentId,
    required this.category,
  });

  @override
  State<_ChecklistContent> createState() => _ChecklistContentState();
}

class _ChecklistContentState extends State<_ChecklistContent> {
  ChecklistFrequency _selectedFrequency = ChecklistFrequency.daily;

  @override
  Widget build(BuildContext context) {
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final equipment = equipmentProvider.getEquipmentById(widget.equipmentId);

    if (equipment == null) {
      return const Center(child: Text('Equipment not found'));
    }

    // Get the items for the current frequency
    final items = checklistProvider.getItemsForCategoryAndFrequency(
      widget.equipmentId,
      widget.category,
      _selectedFrequency,
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(equipment.name),
          const SizedBox(height: 16),
          _buildFrequencySelector(),
          const SizedBox(height: 16),
          if (items.isEmpty) ...[
            // Empty state with helpful message and button
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.checklist_rtl,
                      size: 72,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No ${_selectedFrequency.displayName.toLowerCase()} checklist items found',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use the + button to add items to this checklist',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _addItem(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Item'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Show the checklist items
            Expanded(
              child: _buildChecklistItems(checklistProvider, items),
            ),
          ],
        ],
      ),
    );
  }

  void _addItem(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ChecklistItemDialog(
        equipmentId: widget.equipmentId,
        category: widget.category,
        frequency: _selectedFrequency,
      ),
    );
  }

  Widget _buildHeader(String equipmentName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          equipmentName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Category: ${widget.category}',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequency:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ChecklistFrequency.values.map((frequency) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(frequency.displayName),
                  selected: _selectedFrequency == frequency,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFrequency = frequency;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItems(ChecklistProvider checklistProvider, List<ChecklistItem> items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(item.description),
            subtitle: item.notes != null ? Text(item.notes!) : null,
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
                // Show photo indicator if there's a photo
                if (item.photoUrl != null && item.photoUrl!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.photo, color: Colors.blue),
                    onPressed: () => _showPhotoDialog(context, item),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editChecklistItem(context, item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteChecklistItem(context, item.id),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Result:',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                              labelText: 'Custom result (e.g., numerical value)',
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(text: item.result),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                _updateItemResult(context, item, value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Photo capture button
                        ElevatedButton.icon(
                          onPressed: () => _capturePhoto(context, item),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Add Photo'),
                        ),
                      ],
                    ),
                    
                    // Display photo if available
                    if (item.photoUrl != null && item.photoUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildPhotoThumbnail(item),
                    ],
                    
                    // Notes field
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Comment on the issue',
                        border: OutlineInputBorder(),
                        hintText: 'Add detailed notes about this item',
                      ),
                      controller: TextEditingController(text: item.notes ?? ''),
                      maxLines: 3,
                      onChanged: (value) {
                        final updatedItem = item.copyWith(notes: value);
                        checklistProvider.updateItem(updatedItem);
                      },
                    ),
                  ],
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
      onPressed: () => _updateItemResult(context, item, resultText),
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
      default:
        // For numerical values or custom text
        return Colors.grey.shade700;
    }
  }

  void _editChecklistItem(BuildContext context, ChecklistItem item) {
    showDialog(
      context: context,
      builder: (context) => _ChecklistItemDialog(
        equipmentId: widget.equipmentId,
        category: widget.category,
        frequency: item.frequency,
        existingItem: item,
      ),
    );
  }

  void _deleteChecklistItem(BuildContext context, String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this checklist item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ChecklistProvider>(context, listen: false)
                  .deleteItem(itemId);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
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

  // Build a thumbnail of the photo
  Widget _buildPhotoThumbnail(ChecklistItem item) {
    if (item.photoUrl == null || item.photoUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showPhotoDialog(context, item),
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
  final ChecklistFrequency? frequency;
  final ChecklistItem? existingItem;

  const _ChecklistItemDialog({
    required this.equipmentId,
    required this.category,
    this.frequency,
    this.existingItem,
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
    _frequency = widget.frequency ?? ChecklistFrequency.daily;
    
    if (widget.existingItem != null) {
      _descriptionController.text = widget.existingItem!.description;
      if (widget.existingItem!.notes != null) {
        _notesController.text = widget.existingItem!.notes!;
      }
      _resultController.text = widget.existingItem!.result;
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
                  labelText: 'Notes (optional)',
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
      final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
      
      if (widget.existingItem != null) {
        // Update existing item
        final updatedItem = widget.existingItem!.copyWith(
          frequency: _frequency,
          description: _descriptionController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          result: _resultController.text,
        );
        checklistProvider.updateItem(updatedItem);
        
        // Sync with EquipmentProvider
        checklistProvider.syncWithEquipmentProvider(equipmentProvider, updatedItem);
      } else {
        // Add new item
        final newItem = ChecklistItem(
          equipmentId: widget.equipmentId,
          categoryName: widget.category,
          frequency: _frequency,
          description: _descriptionController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          result: _resultController.text,
        );
        checklistProvider.addItem(newItem);
        
        // Sync with EquipmentProvider
        checklistProvider.syncWithEquipmentProvider(equipmentProvider, newItem);
      }
      
      Navigator.of(context).pop();
    }
  }
} 