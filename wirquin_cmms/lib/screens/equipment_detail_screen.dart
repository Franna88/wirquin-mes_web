import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/equipment_provider.dart';
import '../providers/checklist_provider.dart';
import '../models/equipment.dart';
import '../models/maintenance_category.dart';
import 'checklist_screen.dart';
import 'machine_checklist_screen.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final Equipment? equipment;

  const EquipmentDetailScreen({
    super.key,
    this.equipment,
  });

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _id;
  late String _name;
  late String _location;
  late String _department;
  late String _manufacturer;
  late String _model;
  late String _serialNumber;
  late String _installationDate;
  late String _lastMaintenanceDate;
  late String _status;
  late String _machineType;
  
  final List<String> _statusOptions = [
    'Operational',
    'Maintenance',
    'Out of Service',
    'Standby',
  ];

  final List<String> _machineTypeOptions = [
    'General',
    'BETTATEC',
    'Injection Moulding',
    'CNC',
    'Assembly',
    'Other',
  ];
  
  bool _isInit = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_isInit) {
      if (widget.equipment != null) {
        // Editing existing equipment
        _id = widget.equipment!.id;
        _name = widget.equipment!.name;
        _location = widget.equipment!.location;
        _department = widget.equipment!.department;
        _manufacturer = widget.equipment!.manufacturer;
        _model = widget.equipment!.model;
        _serialNumber = widget.equipment!.serialNumber;
        _installationDate = widget.equipment!.installationDate;
        _lastMaintenanceDate = widget.equipment!.lastMaintenanceDate;
        _status = widget.equipment!.status;
        _machineType = widget.equipment!.machineType ?? 'General';
      } else {
        // Adding new equipment
        _id = const Uuid().v4();
        _name = '';
        _location = '';
        _department = '';
        _manufacturer = '';
        _model = '';
        _serialNumber = '';
        _installationDate = '';
        _lastMaintenanceDate = '';
        _status = _statusOptions.first;
        _machineType = _machineTypeOptions.first;
      }
      
      _isInit = true;
    }
  }
  
  void _saveEquipment() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final equipment = Equipment(
        id: _id,
        name: _name,
        location: _location,
        department: _department,
        manufacturer: _manufacturer,
        model: _model,
        serialNumber: _serialNumber,
        installationDate: _installationDate,
        lastMaintenanceDate: _lastMaintenanceDate,
        status: _status,
        machineType: _machineType,
      );
      
      final equipmentProvider = Provider.of<EquipmentProvider>(
        context,
        listen: false,
      );
      
      equipmentProvider.addOrUpdateEquipment(equipment).then((_) {
        // Remove any duplicate maintenance categories
        equipmentProvider.removeDuplicateCategories().then((_) {
          // Show a success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Equipment saved and duplicate categories removed'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to the previous screen
          Navigator.of(context).pop();
        });
      });
    }
  }
  
  void _createDefaultMaintenanceCategories(EquipmentProvider provider) {
    // Create default maintenance categories for new equipment (IM, BT, TER)
    final categories = [
      MaintenanceCategory(
        id: const Uuid().v4(),
        equipmentId: _id,
        type: MaintenanceCategoryType.inspectionMaintenance,
      ),
      MaintenanceCategory(
        id: const Uuid().v4(),
        equipmentId: _id,
        type: MaintenanceCategoryType.basicTasks,
      ),
      MaintenanceCategory(
        id: const Uuid().v4(),
        equipmentId: _id,
        type: MaintenanceCategoryType.technicalEquipmentReview,
      ),
    ];
    
    // Make sure to await all futures to ensure categories are created
    for (final category in categories) {
      provider.addOrUpdateMaintenanceCategory(category);
    }
    
    debugPrint('Created ${categories.length} default maintenance categories for equipment $_id');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.equipment == null ? 'Add Equipment' : 'Edit Equipment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(
                    labelText: 'Equipment Name *',
                    hintText: 'Enter the equipment name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter equipment name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _name = value!;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _location,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'Enter the equipment location',
                  ),
                  onSaved: (value) {
                    _location = value ?? '';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _department,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    hintText: 'Enter the department',
                  ),
                  onSaved: (value) {
                    _department = value ?? '';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _manufacturer,
                  decoration: const InputDecoration(
                    labelText: 'Manufacturer',
                    hintText: 'Enter the manufacturer',
                  ),
                  onSaved: (value) {
                    _manufacturer = value ?? '';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _model,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    hintText: 'Enter the model',
                  ),
                  onSaved: (value) {
                    _model = value ?? '';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _serialNumber,
                  decoration: const InputDecoration(
                    labelText: 'Serial Number',
                    hintText: 'Enter the serial number',
                  ),
                  onSaved: (value) {
                    _serialNumber = value ?? '';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _installationDate,
                  decoration: const InputDecoration(
                    labelText: 'Installation Date',
                    hintText: 'YYYY-MM-DD',
                  ),
                  onSaved: (value) {
                    _installationDate = value ?? '';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _lastMaintenanceDate,
                  decoration: const InputDecoration(
                    labelText: 'Last Maintenance Date',
                    hintText: 'YYYY-MM-DD',
                  ),
                  onSaved: (value) {
                    _lastMaintenanceDate = value ?? '';
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                  ),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _status = value!;
                    });
                  },
                  onSaved: (value) {
                    _status = value!;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _machineType,
                  decoration: const InputDecoration(
                    labelText: 'Machine Type',
                  ),
                  items: _machineTypeOptions.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _machineType = value!;
                    });
                  },
                  onSaved: (value) {
                    _machineType = value!;
                  },
                ),
                const SizedBox(height: 32),
                if (widget.equipment != null) ...[
                  _buildMaintenanceCategories(context),
                  const SizedBox(height: 32),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveEquipment,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        widget.equipment == null ? 'Add Equipment' : 'Save Changes',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMaintenanceCategories(BuildContext context) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final categories = equipmentProvider.getCategoriesForEquipment(_id);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Maintenance Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_machineType.toLowerCase().contains('injection') || 
                _machineType.toLowerCase().contains('mould')) 
              ElevatedButton.icon(
                onPressed: () async {
                  final equipProvider = Provider.of<EquipmentProvider>(
                    context, 
                    listen: false
                  );
                  
                  await equipProvider.addInjectionMouldingChecklists(_id);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Injection Moulding checklists added successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.playlist_add),
                label: const Text('Add IM Checklists'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Only show machine-specific checklist button if this is a machine-type equipment
        if (_machineType != 'General') ...[
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: Colors.blue.shade50,
            child: ListTile(
              title: Text('${_machineType} Checklists'),
              subtitle: const Text('Machine-specific maintenance tasks'),
              trailing: const Icon(Icons.engineering),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MachineChecklistScreen(
                      equipmentId: _id,
                      machineType: _machineType,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        // Regular maintenance categories
        ...categories.map((category) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(category.type.fullName),
              subtitle: Text('Category Code: ${category.type.code}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChecklistScreen(
                      equipmentId: _id,
                      category: category.type.code,
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ],
    );
  }
} 