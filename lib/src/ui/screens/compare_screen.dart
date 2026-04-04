import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../widgets/tt_record_list.dart';

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
                  onPressed: () {
                    state.refresh();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: diff == null
                ? const _EmptyCompare()
                : TabBarView(
                    children: [
                      TTRecordList(
                        rows: diff.added,
                        emptyText: 'No new TTs in the latest upload.',
                      ),
                      TTRecordList(
                        rows: diff.cleared,
                        emptyText: 'No cleared TTs detected.',
                      ),
                      TTRecordList(
                        rows: diff.still,
                        emptyText: 'No still-open TTs detected.',
                      ),
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
