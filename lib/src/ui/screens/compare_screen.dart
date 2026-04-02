import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../storage/types.dart';

class CompareScreen extends StatelessWidget {
  final AppState state;
  const CompareScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: state.changes,
      builder: (context, _) {
        final diff = state.snapshot.diff;
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Compare'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Added'),
                  Tab(text: 'Cleared'),
                  Tab(text: 'Still'),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () => state.refresh(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: diff == null
                ? const _EmptyCompare()
                : TabBarView(
                    children: [
                      _TTList(rows: diff.added, emptyText: 'No new TTs in latest hour.'),
                      _TTList(rows: diff.cleared, emptyText: 'No cleared TTs detected.'),
                      _TTList(rows: diff.still, emptyText: 'No still-open TTs detected.'),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _EmptyCompare extends StatelessWidget {
  const _EmptyCompare();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Upload at least 2 TT reports to compare.\n\nGo to Upload → “Upload TT Report”.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _TTList extends StatelessWidget {
  final List<TTRecord> rows;
  final String emptyText;
  const _TTList({required this.rows, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(child: Text(emptyText));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = rows[i];
        final sev = (r.actualSeverity ?? r.severity ?? '').trim();
        return Card(
          child: ListTile(
            title: Text('${r.category} • TT ${r.ttnumber}'),
            subtitle: Text('Node: ${r.node}'
                '${sev.isEmpty ? '' : '\nSeverity: $sev'}'
                '${(r.icdStatus ?? '').trim().isEmpty ? '' : '\nICD: ${r.icdStatus}'}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

