import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/equipment_provider.dart';
import '../providers/checklist_provider.dart';
import '../models/equipment.dart';
import '../models/maintenance_category.dart';
import '../data/machine_checklists.dart';
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
    'Toilet Seat',
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
      
      equipmentProvider.addOrUpdateEquipment(equipment).then((_) async {
        // Remove any duplicate maintenance categories
        await equipmentProvider.removeDuplicateCategories();
        
        // If this is a new equipment, generate checklists for all types (IM, BT, TER)
        if (widget.equipment == null) {
          debugPrint('Generating checklists for new equipment: $_id');
          
          // Create checklist provider reference
          final checklistProvider = Provider.of<ChecklistProvider>(
            context, 
            listen: false
          );
          
          // Generate checklists for all three types
          for (final type in ['IM', 'BT', 'TER']) {
            debugPrint('Generating $type checklists');
            
            final items = MachineChecklists.initializeAllChecklistsForMachine(_id, type);
            
            // Add each item to the provider
            for (var item in items) {
              await checklistProvider.addItem(item);
            }
          }
          
          debugPrint('Checklists generation completed');
        }
        
        // Show a success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Equipment saved with all checklists'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to the previous screen
          Navigator.of(context).pop();
        }
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
                _buildStatusDropdown(),
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
  
  Widget _buildStatusDropdown() {
    String displayValue = widget.equipment?.status ?? _status;
    
    // Convert "Out of Service" to "Toilet Seat" for display purposes
    if (displayValue == 'Out of Service') {
      displayValue = 'Toilet Seat';
    }
  
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: displayValue,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.arrow_drop_down_circle_outlined),
          elevation: 2,
          style: const TextStyle(color: Colors.black87),
          onChanged: (String? newValue) {
            setState(() {
              // Convert "Toilet Seat" back to "Out of Service" for storage
              String valueToStore = newValue!;
              if (newValue == 'Toilet Seat') {
                valueToStore = 'Out of Service';
              }
              
              _status = valueToStore;
            });
          },
          items: _statusOptions.map<DropdownMenuItem<String>>((String value) {
            Color itemColor;
            IconData statusIcon;
            
            switch (value) {
              case 'Operational':
                itemColor = Colors.green;
                statusIcon = Icons.check_circle_rounded;
                break;
              case 'Maintenance':
                itemColor = Colors.orange;
                statusIcon = Icons.engineering_rounded;
                break;
              case 'Toilet Seat':
                itemColor = Colors.red;
                statusIcon = Icons.do_not_disturb_on_rounded;
                break;
              default:
                itemColor = Colors.grey;
                statusIcon = Icons.help_outline_rounded;
            }
            
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Icon(statusIcon, color: itemColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: TextStyle(
                      color: itemColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
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
        
        // Direct access to machine checklists - no expansion needed
        const Text(
          'Machine Checklists',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Inspection & Maintenance (IM)
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.shade200),
          ),
          child: ListTile(
            leading: Icon(Icons.engineering, color: Colors.blue.shade700),
            title: const Text('Inspection & Maintenance (IM)'),
            subtitle: const Text('Detailed equipment inspection tasks'),
            trailing: const Icon(Icons.arrow_forward_ios),
            tileColor: Colors.blue.shade50,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MachineChecklistScreen(
                    equipmentId: _id,
                    machineType: 'IM',
                  ),
                ),
              );
            },
          ),
        ),
        
        // Basic Tasks (BT)
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.green.shade200),
          ),
          child: ListTile(
            leading: Icon(Icons.build_rounded, color: Colors.green.shade700),
            title: const Text('Basic Tasks (BT)'),
            subtitle: const Text('Routine maintenance activities'),
            trailing: const Icon(Icons.arrow_forward_ios),
            tileColor: Colors.green.shade50,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MachineChecklistScreen(
                    equipmentId: _id,
                    machineType: 'BT',
                  ),
                ),
              );
            },
          ),
        ),
        
        // Technical Equipment Review (TER)
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange.shade200),
          ),
          child: ListTile(
            leading: Icon(Icons.checklist_rounded, color: Colors.orange.shade700),
            title: const Text('Technical Equipment Review (TER)'),
            subtitle: const Text('Comprehensive technical assessments'),
            trailing: const Icon(Icons.arrow_forward_ios),
            tileColor: Colors.orange.shade50,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MachineChecklistScreen(
                    equipmentId: _id,
                    machineType: 'TER',
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        const Text(
          'Custom Maintenance Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Regular maintenance categories
        if (categories.isEmpty)
          Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                'No custom categories',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              subtitle: const Text('All standard checklists are available above'),
            ),
          )
        else
          ...categories.map((category) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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