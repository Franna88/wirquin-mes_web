import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

class ExcelParser {
  Future<Excel?> loadExcelFile(dynamic input) async {
    try {
      if (kIsWeb) {
        if (input is Uint8List) {
          return Excel.decodeBytes(input);
        } else {
          print('For web, input should be Uint8List byte data');
          return null;
        }
      } else {
        if (input is String) {
          // Handle file path for mobile/desktop
          var bytes = await File(input).readAsBytes();
          return Excel.decodeBytes(bytes);
        } else if (input is Uint8List) {
          return Excel.decodeBytes(input);
        } else {
          print('Invalid input type for Excel loading');
          return null;
        }
      }
    } catch (e) {
      print('Error loading Excel file: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> extractMaintenanceData(dynamic input) async {
    final excel = await loadExcelFile(input);
    if (excel == null) return [];

    final data = <Map<String, dynamic>>[];
    
    try {
      // Print available sheets for debugging
      print('Available sheets: ${excel.tables.keys.join(', ')}');
      
      for (var table in excel.tables.keys) {
        print('Processing sheet: $table');
        final sheet = excel.tables[table];
        if (sheet == null) continue;

        // Print sheet dimensions for debugging
        print('Sheet dimensions: ${sheet.maxRows} rows x ${sheet.maxCols} columns');

        // Extract headers
        final headers = <String>[];
        for (var cell in sheet.row(0)) {
          final header = cell?.value?.toString() ?? '';
          headers.add(header);
          print('Found header: $header');
        }

        // Extract data rows
        for (var i = 1; i < sheet.maxRows; i++) {
          final row = sheet.row(i);
          if (row.any((cell) => cell?.value != null)) {
            final rowData = <String, dynamic>{};
            for (var j = 0; j < headers.length && j < row.length; j++) {
              if (headers[j].isNotEmpty) {
                rowData[headers[j]] = row[j]?.value;
              }
            }
            if (rowData.isNotEmpty) {
              data.add(rowData);
              print('Added row $i: ${rowData.keys.join(', ')}');
            }
          }
        }
      }
    } catch (e) {
      print('Error extracting data: $e');
    }

    return data;
  }

  // Try to extract data from a specific sheet
  Future<List<Map<String, dynamic>>> extractDataFromSheet(dynamic input, String sheetName) async {
    final excel = await loadExcelFile(input);
    if (excel == null) return [];

    final data = <Map<String, dynamic>>[];
    
    try {
      if (!excel.tables.containsKey(sheetName)) {
        print('Sheet $sheetName not found. Available sheets: ${excel.tables.keys.join(', ')}');
        return [];
      }
      
      final sheet = excel.tables[sheetName]!;
      
      // Extract headers
      final headers = <String>[];
      for (var cell in sheet.row(0)) {
        headers.add(cell?.value?.toString() ?? '');
      }

      // Extract data rows
      for (var i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.any((cell) => cell?.value != null)) {
          final rowData = <String, dynamic>{};
          for (var j = 0; j < headers.length && j < row.length; j++) {
            if (headers[j].isNotEmpty) {
              rowData[headers[j]] = row[j]?.value;
            }
          }
          if (rowData.isNotEmpty) {
            data.add(rowData);
          }
        }
      }
    } catch (e) {
      print('Error extracting data from sheet $sheetName: $e');
    }

    return data;
  }

  // Additional methods to extract specific data will be added here
  // after we analyze the Excel file structure
} 