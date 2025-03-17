import 'dart:io';
import 'package:excel/excel.dart';

void main() async {
  try {
    // The Excel file is directly in the wirquin_cmms directory
    final file = File('MPE-F-001 - Maintenance Sheets (1).xls');
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    
    print('Excel file loaded successfully!');
    print('Sheets in the workbook: ${excel.tables.keys.join(', ')}');
    
    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName]!;
      print('\n--- Sheet: $sheetName ---');
      print('Dimensions: ${sheet.maxRows} rows x ${sheet.maxCols} columns');
      
      // Print headers (first row)
      print('Headers:');
      final headers = <String>[];
      for (final cell in sheet.row(0)) {
        final header = cell?.value?.toString() ?? '';
        headers.add(header);
        if (header.isNotEmpty) {
          print('  - $header');
        }
      }
      
      // Print the first 5 data rows
      print('Sample data (first 5 rows):');
      for (var i = 1; i < sheet.maxRows && i <= 5; i++) {
        final row = sheet.row(i);
        final rowData = <String, dynamic>{};
        for (var j = 0; j < headers.length && j < row.length; j++) {
          if (headers[j].isNotEmpty && row[j]?.value != null) {
            rowData[headers[j]] = row[j]?.value.toString();
          }
        }
        if (rowData.isNotEmpty) {
          print('  Row $i: ${rowData.entries.map((e) => '${e.key}: ${e.value}').join(', ')}');
        }
      }
    }
  } catch (e) {
    print('Error reading Excel file: $e');
  }
} 