import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/maintenance_data_provider.dart';
import '../providers/oee_data_provider.dart';
import '../utils/excel_parser.dart';

class ImportDataScreen extends StatefulWidget {
  const ImportDataScreen({super.key});

  @override
  State<ImportDataScreen> createState() => _ImportDataScreenState();
}

class _ImportDataScreenState extends State<ImportDataScreen> {
  bool _isLoading = false;
  String? _error;
  String? _selectedFilePath;
  String? _selectedFileName;
  Uint8List? _fileBytes;
  final ExcelParser _excelParser = ExcelParser();
  List<String> _availableSheets = [];
  String? _selectedSheet;
  String _logMessages = '';

  void _addLogMessage(String message) {
    setState(() {
      _logMessages = '$message\n$_logMessages';
      print(message);
    });
  }

  Future<void> _pickExcelFile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _logMessages = '';
      });

      _addLogMessage('Starting file picking...');
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, // Important for web to get the file bytes
      );

      if (result == null) {
        _addLogMessage('No file selected');
        return;
      }

      _addLogMessage('File selected: ${result.files.single.name}');
      
      setState(() {
        _selectedFileName = result.files.single.name;
        _fileBytes = result.files.single.bytes;
        
        if (!kIsWeb) {
          _selectedFilePath = result.files.single.path;
          _addLogMessage('File path: $_selectedFilePath');
        }
      });

      // Load available sheets
      await _loadSheets();
      
    } catch (e) {
      _addLogMessage('Error picking file: $e');
      setState(() {
        _error = 'Error picking file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSheets() async {
    try {
      setState(() {
        _isLoading = true;
        _availableSheets = [];
        _selectedSheet = null;
      });

      _addLogMessage('Loading Excel sheets...');
      
      dynamic input;
      if (kIsWeb) {
        if (_fileBytes == null) {
          _addLogMessage('No file bytes available for web');
          setState(() {
            _error = 'No file data available';
          });
          return;
        }
        input = _fileBytes;
      } else {
        if (_selectedFilePath == null) {
          _addLogMessage('No file path available for non-web platform');
          setState(() {
            _error = 'No file selected';
          });
          return;
        }
        input = _selectedFilePath;
      }

      final excel = await _excelParser.loadExcelFile(input);
      if (excel != null) {
        final sheetNames = excel.tables.keys.toList();
        _addLogMessage('Found sheets: ${sheetNames.join(', ')}');
        
        setState(() {
          _availableSheets = sheetNames;
          if (_availableSheets.isNotEmpty) {
            _selectedSheet = _availableSheets.first;
          }
        });
      } else {
        _addLogMessage('Failed to load Excel file');
        setState(() {
          _error = 'Failed to load Excel file';
        });
      }
    } catch (e) {
      _addLogMessage('Error loading sheets: $e');
      setState(() {
        _error = 'Error loading sheets: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _addLogMessage('Starting data import...');
      
      if (_selectedSheet == null) {
        _addLogMessage('No sheet selected');
        setState(() {
          _error = 'Please select a sheet first';
        });
        return;
      }

      dynamic input;
      if (kIsWeb) {
        if (_fileBytes == null) {
          _addLogMessage('No file bytes available for web');
          setState(() {
            _error = 'No file data available';
          });
          return;
        }
        input = _fileBytes;
      } else {
        if (_selectedFilePath == null) {
          _addLogMessage('No file path available for non-web platform');
          setState(() {
            _error = 'No file selected';
          });
          return;
        }
        input = _selectedFilePath;
      }

      // Extract data from the selected sheet
      final data = await _excelParser.extractDataFromSheet(input, _selectedSheet!);
      _addLogMessage('Extracted ${data.length} rows from $_selectedSheet');

      if (data.isEmpty) {
        _addLogMessage('No data found in selected sheet');
        setState(() {
          _error = 'No data found in selected sheet';
        });
        return;
      }

      // Determine data type and import to appropriate provider
      final maintenanceProvider = Provider.of<MaintenanceDataProvider>(context, listen: false);
      final oeeProvider = Provider.of<OEEDataProvider>(context, listen: false);

      // Check if data looks like maintenance data or OEE data
      if (_isMaintenanceData(data.first)) {
        _addLogMessage('Importing maintenance data...');
        await maintenanceProvider.loadMaintenanceDataFromMap(data);
      } else if (_isOEEData(data.first)) {
        _addLogMessage('Importing OEE data...');
        await oeeProvider.loadOEEData(data);
      } else {
        _addLogMessage('Unknown data format. Headers: ${data.first.keys.join(', ')}');
        setState(() {
          _error = 'Unknown data format. Could not determine if this is maintenance or OEE data.';
        });
        return;
      }

      _addLogMessage('Data imported successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data imported successfully')),
      );
    } catch (e) {
      _addLogMessage('Error importing data: $e');
      setState(() {
        _error = 'Error importing data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isMaintenanceData(Map<String, dynamic> dataRow) {
    // Check for typical maintenance data headers
    final maintenanceHeaders = [
      'Equipment ID', 'Description', 'Location', 'Status',
      'Last Maintenance Date', 'Next Maintenance Date'
    ];
    
    return maintenanceHeaders.any((header) => 
      dataRow.keys.any((key) => key.toLowerCase().contains(header.toLowerCase())));
  }

  bool _isOEEData(Map<String, dynamic> dataRow) {
    // Check for typical OEE data headers
    final oeeHeaders = [
      'Availability', 'Performance', 'Quality', 'OEE', 'Date'
    ];
    
    return oeeHeaders.any((header) => 
      dataRow.keys.any((key) => key.toLowerCase().contains(header.toLowerCase())));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Import Data',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Import your Excel file with maintenance and OEE data:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickExcelFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Select Excel File'),
          ),
          const SizedBox(height: 16),
          if (_selectedFileName != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.description),
                title: Text(_selectedFileName!),
                subtitle: const Text('Selected Excel File'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_availableSheets.isNotEmpty) ...[
            const Text(
              'Select Sheet:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedSheet,
              isExpanded: true,
              hint: const Text('Select a sheet'),
              items: _availableSheets.map((sheet) {
                return DropdownMenuItem<String>(
                  value: sheet,
                  child: Text(sheet),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSheet = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading || _selectedSheet == null ? null : _importData,
              icon: const Icon(Icons.download_done),
              label: const Text('Import Data'),
            ),
          ],
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_logMessages.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Debug Log:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: SingleChildScrollView(
                child: Text(_logMessages),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import Instructions:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Select your Excel file containing maintenance and OEE data.',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '2. Choose the sheet containing your data.',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '3. Click "Import Data" to load the data into the system.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Note: The system expects specific column headers for correct data import. '
                    'Please ensure your Excel file contains proper headers for Equipment ID, '
                    'Description, Dates, and OEE metrics.',
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 