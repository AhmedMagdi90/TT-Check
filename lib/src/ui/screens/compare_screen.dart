import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../widgets/tt_record_explorer.dart';

class CompareScreen extends StatelessWidget {
  final AppState state;

  const CompareScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: state.changes,
      builder: (context, _) {
        final snapshot = state.snapshot;
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
                  onPressed: () {
                    state.refresh();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: diff == null
                ? const _EmptyCompare()
                : Column(
                    children: [
                      _CompareBatchInfo(
                        latestFileName: snapshot.latestBatch?.fileName,
                        previousFileName: snapshot.previousBatch?.fileName,
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            TTRecordExplorer(
                              title: 'Compare Added',
                              rows: diff.added,
                              emptyText: 'No new TTs in the latest upload.',
                            ),
                            TTRecordExplorer(
                              title: 'Compare Cleared',
                              rows: diff.cleared,
                              emptyText: 'No cleared TTs detected.',
                            ),
                            TTRecordExplorer(
                              title: 'Compare Still',
                              rows: diff.still,
                              emptyText: 'No still-open TTs detected.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _CompareBatchInfo extends StatelessWidget {
  final String? latestFileName;
  final String? previousFileName;

  const _CompareBatchInfo({
    required this.latestFileName,
    required this.previousFileName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (latestFileName != null) Text('Latest file: $latestFileName'),
            if (previousFileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Previous file: $previousFileName'),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCompare extends StatelessWidget {
  const _EmptyCompare();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Upload at least 2 TT reports to compare.\n\nGo to Upload > "Upload TT Report (hourly)".',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
