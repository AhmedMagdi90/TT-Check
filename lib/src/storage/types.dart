class ImportBatch {
  final String id;
  final DateTime receivedAt;
  final String fileName;

  const ImportBatch({
    required this.id,
    required this.receivedAt,
    required this.fileName,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'receivedAt': receivedAt.toIso8601String(),
    'fileName': fileName,
  };

  static ImportBatch fromJson(Map data) {
    return ImportBatch(
      id: (data['id'] as String?) ?? '',
      receivedAt:
          DateTime.tryParse((data['receivedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      fileName: (data['fileName'] as String?) ?? '',
    );
  }
}

class TTRecord {
  final String category;
  final String ttnumber;
  final String node;
  final String? severity;
  final String? actualSeverity;
  final String? icdStatus;
  final DateTime? firstOccurrence;
  final DateTime? lastOccurrence;

  const TTRecord({
    required this.category,
    required this.ttnumber,
    required this.node,
    this.severity,
    this.actualSeverity,
    this.icdStatus,
    this.firstOccurrence,
    this.lastOccurrence,
  });

  String get key => '${category.trim()}|${ttnumber.trim()}';

  Map<String, Object?> toJson() => {
    'category': category,
    'ttnumber': ttnumber,
    'node': node,
    'severity': severity,
    'actualSeverity': actualSeverity,
    'icdStatus': icdStatus,
    'firstOccurrence': firstOccurrence?.toIso8601String(),
    'lastOccurrence': lastOccurrence?.toIso8601String(),
  };

  static TTRecord fromJson(Map data) {
    DateTime? dt(String? s) => s == null ? null : DateTime.tryParse(s);
    return TTRecord(
      category: (data['category'] as String?) ?? '',
      ttnumber: (data['ttnumber'] as String?) ?? '',
      node: (data['node'] as String?) ?? '',
      severity: data['severity'] as String?,
      actualSeverity: data['actualSeverity'] as String?,
      icdStatus: data['icdStatus'] as String?,
      firstOccurrence: dt(data['firstOccurrence'] as String?),
      lastOccurrence: dt(data['lastOccurrence'] as String?),
    );
  }
}

class SiteRecord {
  final String siteName;
  final String? area;
  final String? governorate;

  const SiteRecord({required this.siteName, this.area, this.governorate});

  Map<String, Object?> toJson() => {
    'siteName': siteName,
    'area': area,
    'governorate': governorate,
  };

  static SiteRecord fromJson(Map data) {
    return SiteRecord(
      siteName: (data['siteName'] as String?) ?? '',
      area: data['area'] as String?,
      governorate: data['governorate'] as String?,
    );
  }
}

class DiffResult {
  final List<TTRecord> added;
  final List<TTRecord> cleared;
  final List<TTRecord> still;

  const DiffResult({
    required this.added,
    required this.cleared,
    required this.still,
  });
}

class AppSnapshot {
  final List<String> governorates;
  final List<String> areas;
  final ImportBatch? latestBatch;
  final ImportBatch? previousBatch;
  final DiffResult? diff;
  final Map<String, int> latestCountsByCategory;
  final List<TTRecord> latestRows;

  const AppSnapshot({
    required this.governorates,
    required this.areas,
    required this.latestBatch,
    required this.previousBatch,
    required this.diff,
    required this.latestCountsByCategory,
    required this.latestRows,
  });

  const AppSnapshot.empty()
    : governorates = const [],
      areas = const [],
      latestBatch = null,
      previousBatch = null,
      diff = null,
      latestCountsByCategory = const {},
      latestRows = const [];
}
