import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class ExcelAnalysisScreen extends StatefulWidget {
  const ExcelAnalysisScreen({super.key});

  @override
  State<ExcelAnalysisScreen> createState() => _ExcelAnalysisScreenState();
}

class _ExcelAnalysisScreenState extends State<ExcelAnalysisScreen> {
  bool _isLoading = true;
  String _error = '';
  List<String> _sheetNames = [];
  String? _selectedSheet;
  List<List<String>> _tableData = [];
  List<String> _headers = [];

  @override
  void initState() {
    super.initState();
    _analyzeExcelFile();
  }

  Future<void> _analyzeExcelFile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // Load the Excel file from assets
      final ByteData data = await rootBundle.load('assets/MPE-F-001 - Maintenance Sheets (1).xls');
      final bytes = data.buffer.asUint8List();
      
      try {
        final excel = Excel.decodeBytes(bytes);
        _sheetNames = excel.tables.keys.toList();
        
        if (_sheetNames.isNotEmpty) {
          _selectedSheet = _sheetNames.first;
          _loadSheetData(excel, _selectedSheet!);
        } else {
          setState(() {
            _error = 'No sheets found in the Excel file';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _error = 'Error decoding Excel file: $e';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error reading Excel file: $e';
        _isLoading = false;
      });
    }
  }

  void _loadSheetData(Excel excel, String sheetName) {
    try {
      final sheet = excel.tables[sheetName];
      if (sheet == null) {
        setState(() {
          _error = 'Sheet $sheetName not found';
          _isLoading = false;
        });
        return;
      }

      // Get headers from first row
      _headers = [];
      for (final cell in sheet.row(0)) {
        final header = cell?.value?.toString() ?? '';
        _headers.add(header);
      }

      // Get data rows
      _tableData = [];
      for (var i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.any((cell) => cell?.value != null)) {
          final rowData = <String>[];
          for (var j = 0; j < _headers.length && j < row.length; j++) {
            rowData.add(row[j]?.value?.toString() ?? '');
          }
          _tableData.add(rowData);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading sheet data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _changeSheet(String newSheet) async {
    try {
      setState(() {
        _selectedSheet = newSheet;
        _isLoading = true;
      });
      
      final ByteData data = await rootBundle.load('assets/MPE-F-001 - Maintenance Sheets (1).xls');
      final bytes = data.buffer.asUint8List();
      final excel = Excel.decodeBytes(bytes);
      
      _loadSheetData(excel, newSheet);
    } catch (e) {
      setState(() {
        _error = 'Error changing sheet: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.blue[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Excel Analysis',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Exploring the structure of your Excel file to build a digital version',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error analyzing Excel file:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _analyzeExcelFile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_sheetNames.isEmpty) {
      return const Center(child: Text('No sheets found in the Excel file'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Select Sheet: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedSheet,
                  isExpanded: true,
                  items: _sheetNames.map((sheetName) {
                    return DropdownMenuItem<String>(
                      value: sheetName,
                      child: Text(sheetName),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null && newValue != _selectedSheet) {
                      _changeSheet(newValue);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildTable(),
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_headers.isEmpty || _tableData.isEmpty) {
      return const Center(child: Text('No data available in the selected sheet'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: _headers.map((header) {
            return DataColumn(
              label: Expanded(
                child: Text(
                  header,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
          rows: _tableData.map((rowData) {
            return DataRow(
              cells: List.generate(
                rowData.length,
                (index) => DataCell(Text(rowData[index])),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
} 