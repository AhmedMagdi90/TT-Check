import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../storage/storage.dart';
import '../../storage/types.dart';

class TTRecordList extends StatelessWidget {
  final List<TTRecord> rows;
  final String emptyText;

  const TTRecordList({super.key, required this.rows, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(child: Text(emptyText, textAlign: TextAlign.center));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _TTRecordTile(row: rows[i]),
    );
  }
}

class _TTRecordTile extends StatelessWidget {
  final TTRecord row;

  const _TTRecordTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final severity = (row.actualSeverity ?? row.severity ?? '').trim();
    final icdStatus = (row.icdStatus ?? '').trim();
    final area = Storage.areaForNode(row.node);
    final governorate = Storage.governorateForNode(row.node);
    final location = [
      governorate,
      area,
    ].whereType<String>().where((v) => v.isNotEmpty).join(' / ');
    final details = <String>[
      'Node: ${row.node}',
      if (location.isNotEmpty) 'Location: $location',
      if (severity.isNotEmpty) 'Severity: $severity',
      if (icdStatus.isNotEmpty) 'ICD: $icdStatus',
      if (row.firstOccurrence != null)
        'First: ${_formatDate(row.firstOccurrence!)}',
      if (row.lastOccurrence != null)
        'Last: ${_formatDate(row.lastOccurrence!)}',
    ];

    return Card(
      child: ListTile(
        title: Text('${row.category} | TT ${row.ttnumber}'),
        subtitle: Text(details.join('\n')),
        isThreeLine: details.length > 2,
      ),
    );
  }
}

String _formatDate(DateTime value) {
  return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
}
