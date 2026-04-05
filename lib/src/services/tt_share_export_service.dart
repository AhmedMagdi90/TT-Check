import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../storage/storage.dart';
import '../storage/types.dart';

class TTShareExportService {
  static Future<void> shareRows({
    required String title,
    required List<TTRecord> rows,
    List<MapEntry<String, String>> info = const [],
  }) async {
    final file = await exportRowsToExcel(
      exportName: title,
      rows: rows,
      info: info,
    );
    final summary = buildShareText(title: title, rows: rows, info: info);

    await SharePlus.instance.share(
      ShareParams(subject: title, text: summary, files: [XFile(file.path)]),
    );
  }

  static Future<File> shareExcel({
    required String title,
    required List<TTRecord> rows,
    List<MapEntry<String, String>> info = const [],
  }) async {
    final file = await exportRowsToExcel(
      exportName: title,
      rows: rows,
      info: info,
    );
    await SharePlus.instance.share(
      ShareParams(subject: title, files: [XFile(file.path)]),
    );
    return file;
  }

  static Future<File> exportRowsToExcel({
    required String exportName,
    required List<TTRecord> rows,
    List<MapEntry<String, String>> info = const [],
  }) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    const sheetName = 'TT Data';
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.rename(defaultSheet, sheetName);
    }
    final sheet = excel[sheetName];

    for (final entry in info) {
      sheet.appendRow([TextCellValue(entry.key), TextCellValue(entry.value)]);
    }

    sheet.appendRow([TextCellValue('Export name'), TextCellValue(exportName)]);
    sheet.appendRow([
      TextCellValue('Generated at'),
      TextCellValue(_formatDate(DateTime.now())),
    ]);
    sheet.appendRow([TextCellValue('Rows'), IntCellValue(rows.length)]);
    sheet.appendRow(const <CellValue?>[]);
    sheet.appendRow([
      TextCellValue('Category'),
      TextCellValue('TT Number'),
      TextCellValue('Node'),
      TextCellValue('Governorate'),
      TextCellValue('Area'),
      TextCellValue('Severity'),
      TextCellValue('ICD Status'),
      TextCellValue('First Occurrence'),
      TextCellValue('Last Occurrence'),
    ]);

    for (final row in rows) {
      sheet.appendRow([
        TextCellValue(row.category),
        TextCellValue(row.ttnumber),
        TextCellValue(row.node),
        TextCellValue(Storage.governorateForNode(row.node) ?? ''),
        TextCellValue(Storage.areaForNode(row.node) ?? ''),
        TextCellValue((row.actualSeverity ?? row.severity ?? '').trim()),
        TextCellValue((row.icdStatus ?? '').trim()),
        TextCellValue(
          row.firstOccurrence == null ? '' : _formatDate(row.firstOccurrence!),
        ),
        TextCellValue(
          row.lastOccurrence == null ? '' : _formatDate(row.lastOccurrence!),
        ),
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Excel export failed.');
    }

    final directory = await getTemporaryDirectory();
    final safeName = _sanitizeFileName(exportName);
    final file = File(
      '${directory.path}${Platform.pathSeparator}$safeName.xlsx',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static String buildShareText({
    required String title,
    required List<TTRecord> rows,
    List<MapEntry<String, String>> info = const [],
  }) {
    final buffer = StringBuffer();
    buffer.writeln(title);
    buffer.writeln('Rows: ${rows.length}');
    for (final entry in info) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    buffer.writeln();

    for (final row in rows.take(60)) {
      final severity = (row.actualSeverity ?? row.severity ?? '').trim();
      final location = [
        Storage.governorateForNode(row.node),
        Storage.areaForNode(row.node),
      ].whereType<String>().where((value) => value.isNotEmpty).join(' / ');

      buffer.writeln('${row.category} | TT ${row.ttnumber}');
      buffer.writeln('Node: ${row.node}');
      if (location.isNotEmpty) {
        buffer.writeln('Location: $location');
      }
      if (severity.isNotEmpty) {
        buffer.writeln('Severity: $severity');
      }
      if ((row.icdStatus ?? '').trim().isNotEmpty) {
        buffer.writeln('ICD: ${row.icdStatus!.trim()}');
      }
      buffer.writeln();
    }

    if (rows.length > 60) {
      buffer.writeln('Only the first 60 rows are shown in text.');
      buffer.writeln(
        'The attached Excel file contains the full filtered result.',
      );
    }

    return buffer.toString().trim();
  }
}

String _sanitizeFileName(String value) {
  return value
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .trim();
}

String _formatDate(DateTime value) {
  return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
}
