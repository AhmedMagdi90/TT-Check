import 'package:flutter/material.dart';

import '../../services/tt_share_export_service.dart';
import '../../storage/storage.dart';
import '../../storage/types.dart';
import 'tt_record_list.dart';

class TTExplorerInfo {
  final String label;
  final String value;

  const TTExplorerInfo({required this.label, required this.value});
}

class TTRecordExplorer extends StatefulWidget {
  final String title;
  final List<TTRecord> rows;
  final String emptyText;
  final List<TTExplorerInfo> info;

  const TTRecordExplorer({
    super.key,
    required this.title,
    required this.rows,
    required this.emptyText,
    this.info = const [],
  });

  @override
  State<TTRecordExplorer> createState() => _TTRecordExplorerState();
}

class _TTRecordExplorerState extends State<TTRecordExplorer> {
  final TextEditingController _searchController = TextEditingController();

  late List<_ExplorerRow> _allRows;
  String _query = '';
  String? _selectedCategory;
  String? _selectedSeverity;
  String? _selectedGovernorate;
  String? _selectedArea;
  String? _selectedIcdStatus;

  @override
  void initState() {
    super.initState();
    _allRows = _mapRows(widget.rows);
  }

  @override
  void didUpdateWidget(covariant TTRecordExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) {
      _allRows = _mapRows(widget.rows);
      _clearInvalidSelections();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ExplorerRow> get _filteredRows {
    final results = _allRows.where((row) {
      if (_selectedCategory != null && row.category != _selectedCategory) {
        return false;
      }
      if (_selectedSeverity != null && row.severity != _selectedSeverity) {
        return false;
      }
      if (_selectedGovernorate != null &&
          row.governorate != _selectedGovernorate) {
        return false;
      }
      if (_selectedArea != null && row.area != _selectedArea) {
        return false;
      }
      if (_selectedIcdStatus != null && row.icdStatus != _selectedIcdStatus) {
        return false;
      }
      if (_query.isEmpty) {
        return true;
      }
      return row.searchText.contains(_query);
    }).toList();

    if (_query.isNotEmpty) {
      results.sort((a, b) {
        final score = _matchScore(a).compareTo(_matchScore(b));
        if (score != 0) return score;
        return a.record.ttnumber.compareTo(b.record.ttnumber);
      });
    }

    return results;
  }

  List<String> get _categories => _uniqueSorted(
    _allRows.map((row) => row.category).where((value) => value.isNotEmpty),
  );

  List<String> get _severities => _uniqueSorted(
    _allRows.map((row) => row.severity).where((value) => value.isNotEmpty),
  );

  List<String> get _governorates => _uniqueSorted(
    _allRows.map((row) => row.governorate).where((value) => value.isNotEmpty),
  );

  List<String> get _areas {
    final rows = _selectedGovernorate == null
        ? _allRows
        : _allRows.where((row) => row.governorate == _selectedGovernorate);
    return _uniqueSorted(
      rows.map((row) => row.area).where((value) => value.isNotEmpty),
    );
  }

  List<String> get _icdStatuses => _uniqueSorted(
    _allRows.map((row) => row.icdStatus).where((value) => value.isNotEmpty),
  );

  bool get _hasActiveFilters =>
      _query.isNotEmpty ||
      _selectedCategory != null ||
      _selectedSeverity != null ||
      _selectedGovernorate != null ||
      _selectedArea != null ||
      _selectedIcdStatus != null;

  Future<void> _shareFilteredRows() async {
    try {
      final rows = _filteredRows.map((row) => row.record).toList();
      await TTShareExportService.shareRows(
        title: widget.title,
        rows: rows,
        info: widget.info
            .map((item) => MapEntry(item.label, item.value))
            .toList(),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share failed: $error')));
    }
  }

  Future<void> _exportFilteredRows() async {
    try {
      final rows = _filteredRows.map((row) => row.record).toList();
      final file = await TTShareExportService.shareExcel(
        title: widget.title,
        rows: rows,
        info: widget.info
            .map((item) => MapEntry(item.label, item.value))
            .toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Excel file ready: ${file.path}')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Excel export failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRows = _filteredRows;
    final visibleRecords = filteredRows.map((row) => row.record).toList();
    final theme = Theme.of(context);

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.info.isNotEmpty) ...[
                  Text('Source', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final item in widget.info)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${item.label}: ${item.value}'),
                    ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText:
                        'Search TT, node, category, area, governorate, ICD',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _query = '';
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _query = value.trim().toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  initiallyExpanded: _hasActiveFilters,
                  title: const Text('Smart filters'),
                  subtitle: Text(
                    '${filteredRows.length} of ${_allRows.length} rows',
                  ),
                  children: [
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth >= 700
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: width,
                              child: _FilterDropdown(
                                label: 'Category',
                                value: _selectedCategory,
                                options: _categories,
                                allLabel: 'All categories',
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _FilterDropdown(
                                label: 'Severity',
                                value: _selectedSeverity,
                                options: _severities,
                                allLabel: 'All severities',
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSeverity = value;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _FilterDropdown(
                                label: 'Governorate',
                                value: _selectedGovernorate,
                                options: _governorates,
                                allLabel: 'All governorates',
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGovernorate = value;
                                    if (value != null &&
                                        _selectedArea != null &&
                                        !_areas.contains(_selectedArea)) {
                                      _selectedArea = null;
                                    }
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _FilterDropdown(
                                label: 'Area',
                                value: _selectedArea,
                                options: _areas,
                                allLabel: 'All areas',
                                onChanged: (value) {
                                  setState(() {
                                    _selectedArea = value;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _FilterDropdown(
                                label: 'ICD status',
                                value: _selectedIcdStatus,
                                options: _icdStatuses,
                                allLabel: 'All ICD values',
                                onChanged: (value) {
                                  setState(() {
                                    _selectedIcdStatus = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _hasActiveFilters ? _clearFilters : null,
                        icon: const Icon(Icons.filter_alt_off_outlined),
                        label: const Text('Clear filters'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: visibleRecords.isEmpty
                          ? null
                          : _shareFilteredRows,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                    ),
                    OutlinedButton.icon(
                      onPressed: visibleRecords.isEmpty
                          ? null
                          : _exportFilteredRows,
                      icon: const Icon(Icons.table_view_outlined),
                      label: const Text('Export Excel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TTRecordList(
            rows: visibleRecords,
            emptyText: _hasActiveFilters
                ? 'No TTs match the current search or filters.'
                : widget.emptyText,
          ),
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _query = '';
      _selectedCategory = null;
      _selectedSeverity = null;
      _selectedGovernorate = null;
      _selectedArea = null;
      _selectedIcdStatus = null;
    });
  }

  void _clearInvalidSelections() {
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }
    if (!_severities.contains(_selectedSeverity)) {
      _selectedSeverity = null;
    }
    if (!_governorates.contains(_selectedGovernorate)) {
      _selectedGovernorate = null;
    }
    if (!_areas.contains(_selectedArea)) {
      _selectedArea = null;
    }
    if (!_icdStatuses.contains(_selectedIcdStatus)) {
      _selectedIcdStatus = null;
    }
  }

  int _matchScore(_ExplorerRow row) {
    if (_query.isEmpty) return 0;
    if (row.ttNumber == _query) return 0;
    if (row.ttNumber.contains(_query)) return 1;
    if (row.node.startsWith(_query)) return 2;
    if (row.node.contains(_query)) return 3;
    if (row.category.toLowerCase().contains(_query)) return 4;
    if (row.location.contains(_query)) return 5;
    if (row.icdStatus.toLowerCase().contains(_query)) return 6;
    return 7;
  }

  List<_ExplorerRow> _mapRows(List<TTRecord> rows) {
    return rows.map(_ExplorerRow.fromRecord).toList();
  }

  List<String> _uniqueSorted(Iterable<String> values) {
    final items = values.toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return items;
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final String allLabel;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.allLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(allLabel)),
        for (final option in options)
          DropdownMenuItem<String?>(value: option, child: Text(option)),
      ],
      onChanged: onChanged,
    );
  }
}

class _ExplorerRow {
  final TTRecord record;
  final String category;
  final String ttNumber;
  final String node;
  final String severity;
  final String governorate;
  final String area;
  final String location;
  final String icdStatus;
  final String searchText;

  const _ExplorerRow({
    required this.record,
    required this.category,
    required this.ttNumber,
    required this.node,
    required this.severity,
    required this.governorate,
    required this.area,
    required this.location,
    required this.icdStatus,
    required this.searchText,
  });

  factory _ExplorerRow.fromRecord(TTRecord record) {
    final governorate = Storage.governorateForNode(record.node) ?? '';
    final area = Storage.areaForNode(record.node) ?? '';
    final severity = (record.actualSeverity ?? record.severity ?? '').trim();
    final icdStatus = (record.icdStatus ?? '').trim();
    final location = [
      governorate,
      area,
    ].where((value) => value.isNotEmpty).join(' / ');

    return _ExplorerRow(
      record: record,
      category: record.category,
      ttNumber: record.ttnumber.toLowerCase(),
      node: record.node.toLowerCase(),
      severity: severity,
      governorate: governorate,
      area: area,
      location: location.toLowerCase(),
      icdStatus: icdStatus,
      searchText: [
        record.category,
        record.ttnumber,
        record.node,
        governorate,
        area,
        severity,
        icdStatus,
      ].join(' ').toLowerCase(),
    );
  }
}
