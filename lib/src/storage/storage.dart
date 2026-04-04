import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:hive/hive.dart';

import '../storage/types.dart';

class Storage {
  static const _boxMeta = 'meta';
  static const _boxSites = 'sites';
  static const _boxTTRows = 'tt_rows';
  static const _boxTTIndex = 'tt_index';

  static Future<void> openBoxes() async {
    await Hive.openBox(_boxMeta);
    await Hive.openBox(_boxSites);
    await Hive.openBox(_boxTTRows);
    await Hive.openBox(_boxTTIndex);
  }

  static Box get _meta => Hive.box(_boxMeta);
  static Box get _sites => Hive.box(_boxSites);
  static Box get _ttRows => Hive.box(_boxTTRows);
  static Box get _ttIndex => Hive.box(_boxTTIndex);

  static SiteRecord? siteForNode(String node) {
    final record = _sites.get(node.trim());
    if (record is Map) return SiteRecord.fromJson(record);
    return null;
  }

  // ---------- Site Count ----------
  static Future<void> upsertSites(List<SiteRecord> sites) async {
    final map = <String, Map<String, Object?>>{};
    for (final s in sites) {
      if (s.siteName.trim().isEmpty) continue;
      map[s.siteName.trim()] = s.toJson();
    }
    await _sites.putAll(map);
  }

  static List<String> getGovernorates() {
    final governorates = <String>{};
    for (final key in _sites.keys) {
      final m = _sites.get(key);
      if (m is Map) {
        final governorate = (m['governorate'] as String?)?.trim();
        if (governorate != null && governorate.isNotEmpty) {
          governorates.add(governorate);
        }
      }
    }
    final list = governorates.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  static List<String> getAreas({String? governorateFilter}) {
    final areas = <String>{};
    for (final key in _sites.keys) {
      final m = _sites.get(key);
      if (m is Map) {
        final governorate = (m['governorate'] as String?)?.trim();
        if (governorateFilter != null &&
            (governorate == null ||
                governorate.toLowerCase() != governorateFilter.toLowerCase())) {
          continue;
        }
        final area = (m['area'] as String?)?.trim();
        if (area != null && area.isNotEmpty) areas.add(area);
      }
    }
    final list = areas.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  static String? areaForNode(String node) {
    final area = siteForNode(node)?.area?.trim();
    if (area != null && area.isNotEmpty) return area;
    return null;
  }

  static String? governorateForNode(String node) {
    final governorate = siteForNode(node)?.governorate?.trim();
    if (governorate != null && governorate.isNotEmpty) return governorate;
    return null;
  }

  // ---------- Batches ----------
  static List<ImportBatch> getBatches() {
    final raw = _meta.get('batches');
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map(ImportBatch.fromJson)
            .where((b) => b.id.isNotEmpty)
            .sortedBy((b) => b.receivedAt)
            .reversed
            .toList();
      }
    }
    return const [];
  }

  static Future<void> _saveBatches(List<ImportBatch> batches) async {
    await _meta.put(
      'batches',
      jsonEncode(batches.map((b) => b.toJson()).toList()),
    );
  }

  static Future<ImportBatch> createBatch({required String fileName}) async {
    final now = DateTime.now();
    final id = '${now.toIso8601String()}_${Random().nextInt(1 << 32)}';
    final batch = ImportBatch(id: id, receivedAt: now, fileName: fileName);
    final batches = getBatches();
    final next = [batch, ...batches];
    await _saveBatches(next);
    return batch;
  }

  // ---------- TT storage ----------
  static String _rowKey(String batchId, String ttKey) => '$batchId|$ttKey';

  static Future<void> putBatchRows(String batchId, List<TTRecord> rows) async {
    final keys = <String>[];
    final map = <String, Map<String, Object?>>{};
    for (final r in rows) {
      if (r.ttnumber.trim().isEmpty) continue;
      final key = r.key;
      keys.add(key);
      map[_rowKey(batchId, key)] = r.toJson();
    }
    await _ttRows.putAll(map);
    await _ttIndex.put(batchId, keys);
  }

  static List<String> _keysForBatch(String batchId) {
    final v = _ttIndex.get(batchId);
    if (v is List) return v.whereType<String>().toList();
    return const [];
  }

  static TTRecord? _getRow(String batchId, String ttKey) {
    final m = _ttRows.get(_rowKey(batchId, ttKey));
    if (m is Map) return TTRecord.fromJson(m);
    return null;
  }

  static List<TTRecord> getRowsForBatch(
    String batchId, {
    String? areaFilter,
    String? governorateFilter,
  }) {
    final keys = _keysForBatch(batchId);
    final out = <TTRecord>[];
    for (final k in keys) {
      final r = _getRow(batchId, k);
      if (r == null) continue;
      if (governorateFilter != null) {
        final governorate = governorateForNode(r.node);
        if (governorate == null ||
            governorate.toLowerCase() != governorateFilter.toLowerCase()) {
          continue;
        }
      }
      if (areaFilter != null) {
        final area = areaForNode(r.node);
        if (area == null || area.toLowerCase() != areaFilter.toLowerCase()) {
          continue;
        }
      }
      out.add(r);
    }
    return out;
  }

  static DiffResult diff(
    String latestBatchId,
    String previousBatchId, {
    String? areaFilter,
    String? governorateFilter,
  }) {
    final latest = getRowsForBatch(
      latestBatchId,
      areaFilter: areaFilter,
      governorateFilter: governorateFilter,
    );
    final prev = getRowsForBatch(
      previousBatchId,
      areaFilter: areaFilter,
      governorateFilter: governorateFilter,
    );

    final latestByKey = {for (final r in latest) r.key: r};
    final prevByKey = {for (final r in prev) r.key: r};

    final addedKeys = latestByKey.keys.toSet().difference(
      prevByKey.keys.toSet(),
    );
    final clearedKeys = prevByKey.keys.toSet().difference(
      latestByKey.keys.toSet(),
    );
    final stillKeys = latestByKey.keys.toSet().intersection(
      prevByKey.keys.toSet(),
    );

    int weight(TTRecord r) {
      final cat = r.category.toLowerCase();
      final sev = (r.actualSeverity ?? r.severity ?? '').toLowerCase();
      final sevW = sev.contains('critical')
          ? 0
          : sev.contains('major')
          ? 1
          : sev.contains('minor')
          ? 2
          : 3;
      final catW = cat.contains('down site')
          ? 0
          : cat.contains('down cells') || cat.contains('down cell')
          ? 1
          : 2;
      final age = r.firstOccurrence == null
          ? 0
          : DateTime.now().difference(r.firstOccurrence!).inMinutes;
      return (catW * 1000000) + (sevW * 10000) - min(age, 9999);
    }

    List<TTRecord> sort(List<TTRecord> xs) =>
        xs.sorted((a, b) => weight(a).compareTo(weight(b)));

    return DiffResult(
      added: sort(addedKeys.map((k) => latestByKey[k]!).toList()),
      cleared: sort(clearedKeys.map((k) => prevByKey[k]!).toList()),
      still: sort(stillKeys.map((k) => latestByKey[k]!).toList()),
    );
  }

  static Future<AppSnapshot> buildSnapshot({
    String? selectedArea,
    String? selectedGovernorate,
  }) async {
    final governorates = getGovernorates();
    final areas = getAreas(governorateFilter: selectedGovernorate);
    final batches = getBatches();
    final latest = batches.isNotEmpty ? batches[0] : null;
    final previous = batches.length >= 2 ? batches[1] : null;

    DiffResult? diffResult;
    Map<String, int> counts = {};
    List<TTRecord> latestRows = const [];
    if (latest != null) {
      latestRows = getRowsForBatch(
        latest.id,
        areaFilter: selectedArea,
        governorateFilter: selectedGovernorate,
      );
      counts = latestRows
          .groupListsBy((r) => r.category)
          .map((k, v) => MapEntry(k, v.length));
    }
    if (latest != null && previous != null) {
      diffResult = diff(
        latest.id,
        previous.id,
        areaFilter: selectedArea,
        governorateFilter: selectedGovernorate,
      );
    }

    return AppSnapshot(
      governorates: governorates,
      areas: areas,
      latestBatch: latest,
      previousBatch: previous,
      diff: diffResult,
      latestCountsByCategory: counts,
      latestRows: latestRows,
    );
  }
}
