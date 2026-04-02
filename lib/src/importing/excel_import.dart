import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../storage/types.dart';

class ExcelImport {
  static List<SiteRecord> parseSiteCount(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.sheets.values.firstOrNull;
    if (sheet == null) return const [];

    final header = _readHeader(sheet);
    final idxSiteName = _idx(header, 'SiteName');
    final idxArea = _idx(header, 'Area');
    final idxGov = _idx(header, 'Governorate');

    final out = <SiteRecord>[];
    for (var r = 1; r < sheet.maxRows; r++) {
      final row = sheet.row(r);
      final site = _cell(row, idxSiteName)?.trim();
      if (site == null || site.isEmpty) continue;
      out.add(
        SiteRecord(
          siteName: site,
          area: _cell(row, idxArea)?.trim(),
          governorate: _cell(row, idxGov)?.trim(),
        ),
      );
    }
    return out;
  }

  static List<TTRecord> parseTTReport(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final out = <TTRecord>[];

    for (final entry in excel.sheets.entries) {
      final sheetName = entry.key;
      final sheet = entry.value;
      if (sheet.maxRows <= 1) continue;

      final header = _readHeader(sheet);
      final idxTT = _idx(header, 'Ttnumber');
      final idxNode = _idx(header, 'Node');
      final idxSev = _idx(header, 'Severity');
      final idxActualSev = _idx(header, 'Actualseverity');
      final idxIcd = _idx(header, 'Icdstatus');
      final idxFirst = _idx(header, 'Firstoccurrence');
      final idxLast = _idx(header, 'Lastoccurrence');

      for (var r = 1; r < sheet.maxRows; r++) {
        final row = sheet.row(r);
        final ttnumber = _cell(row, idxTT)?.trim();
        final node = _cell(row, idxNode)?.trim();
        if (ttnumber == null || ttnumber.isEmpty) continue;
        if (node == null || node.isEmpty) continue;

        out.add(
          TTRecord(
            category: _normalizeCategory(sheetName),
            ttnumber: ttnumber,
            node: node,
            severity: _cell(row, idxSev)?.trim(),
            actualSeverity: _cell(row, idxActualSev)?.trim(),
            icdStatus: _cell(row, idxIcd)?.trim(),
            firstOccurrence: _parseDate(_cell(row, idxFirst)),
            lastOccurrence: _parseDate(_cell(row, idxLast)),
          ),
        );
      }
    }

    return out;
  }

  static String _normalizeCategory(String sheetName) {
    final s = sheetName.replaceAll('_', ' ').trim();
    // Keep only the readable part (e.g. "Down Site_2" -> "Down Site")
    return s.replaceAll(RegExp(r'\s+\d+$'), '').trim();
  }

  static List<String> _readHeader(Sheet sheet) {
    if (sheet.maxRows == 0) return const [];
    final row = sheet.row(0);
    return row.map((c) => (c?.value?.toString() ?? '').trim()).toList();
  }

  static int _idx(List<String> header, String name) {
    final target = name.toLowerCase().replaceAll(' ', '');
    for (var i = 0; i < header.length; i++) {
      final h = header[i].toLowerCase().replaceAll(' ', '');
      if (h == target) return i;
    }
    return -1;
  }

  static String? _cell(List<Data?> row, int idx) {
    if (idx < 0 || idx >= row.length) return null;
    final v = row[idx]?.value;
    return v?.toString();
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;

    // Common formats seen in exports. If your file uses a different format,
    // we’ll add it once we see a sample.
    final fmts = <DateFormat>[
      DateFormat('M/d/yyyy H:mm:ss'),
      DateFormat('M/d/yyyy H:mm'),
      DateFormat('d/M/yyyy H:mm:ss'),
      DateFormat('d/M/yyyy H:mm'),
      DateFormat('yyyy-MM-ddTHH:mm:ss'),
      DateFormat('yyyy-MM-dd HH:mm:ss'),
    ];
    for (final f in fmts) {
      try {
        return f.parseStrict(s);
      } catch (_) {}
    }
    return DateTime.tryParse(s);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

