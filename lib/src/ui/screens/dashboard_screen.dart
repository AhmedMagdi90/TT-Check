import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../storage/types.dart';
import '../widgets/tt_record_explorer.dart';
import 'tt_records_screen.dart';

class DashboardScreen extends StatelessWidget {
  final AppState state;

  const DashboardScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: state.changes,
      builder: (context, _) {
        final snap = state.snapshot;

        void openRows({
          required String title,
          required List<TTRecord> rows,
          required String emptyText,
        }) {
          final info = <TTExplorerInfo>[
            if (snap.latestBatch != null)
              TTExplorerInfo(
                label: 'Source file',
                value: snap.latestBatch!.fileName,
              ),
            if (state.selectedGovernorate != null)
              TTExplorerInfo(
                label: 'Governorate filter',
                value: state.selectedGovernorate!,
              ),
            if (state.selectedArea != null)
              TTExplorerInfo(label: 'Area filter', value: state.selectedArea!),
          ];

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TTRecordsScreen(
                title: _buildDetailsTitle(
                  title: title,
                  governorate: state.selectedGovernorate,
                  area: state.selectedArea,
                ),
                rows: rows,
                emptyText: emptyText,
                info: info,
              ),
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('TT Check'),
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
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _BatchInfo(
                    latest: snap.latestBatch,
                    previous: snap.previousBatch,
                  ),
                  const SizedBox(height: 12),
                  _FiltersCard(
                    governorates: snap.governorates,
                    selectedGovernorate: state.selectedGovernorate,
                    onGovernorateChanged: (value) {
                      state.setGovernorate(value);
                    },
                    areas: snap.areas,
                    selectedArea: state.selectedArea,
                    onAreaChanged: (value) {
                      state.setArea(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _PriorityCards(
                    latestRows: snap.latestRows,
                    diff: snap.diff,
                    onOpenRows: openRows,
                  ),
                  const SizedBox(height: 12),
                  _OtherCounts(
                    counts: snap.latestCountsByCategory,
                    latestRows: snap.latestRows,
                    onOpenRows: openRows,
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _buildDetailsTitle({
  required String title,
  required String? governorate,
  required String? area,
}) {
  final filters = <String>[
    if (governorate != null) governorate,
    if (area != null) area,
  ];
  if (filters.isEmpty) return title;
  return '$title (${filters.join(' / ')})';
}

class _FiltersCard extends StatelessWidget {
  final List<String> governorates;
  final String? selectedGovernorate;
  final ValueChanged<String?> onGovernorateChanged;
  final List<String> areas;
  final String? selectedArea;
  final ValueChanged<String?> onAreaChanged;

  const _FiltersCard({
    required this.governorates,
    required this.selectedGovernorate,
    required this.onGovernorateChanged,
    required this.areas,
    required this.selectedArea,
    required this.onAreaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: selectedGovernorate,
              decoration: const InputDecoration(
                labelText: 'Governorate',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All governorates'),
                ),
                for (final governorate in governorates)
                  DropdownMenuItem<String?>(
                    value: governorate,
                    child: Text(governorate),
                  ),
              ],
              onChanged: onGovernorateChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: selectedArea,
              decoration: const InputDecoration(
                labelText: 'Area',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All areas'),
                ),
                for (final area in areas)
                  DropdownMenuItem<String?>(value: area, child: Text(area)),
              ],
              onChanged: onAreaChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchInfo extends StatelessWidget {
  final ImportBatch? latest;
  final ImportBatch? previous;

  const _BatchInfo({required this.latest, required this.previous});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (latest == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No TT batches yet. Go to Upload > "Upload TT Report (hourly)".',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latest upload', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('File: ${latest!.fileName}'),
            Text('Time: ${latest!.receivedAt}'),
            if (previous != null) ...[
              const Divider(height: 20),
              Text('Previous file: ${previous!.fileName}'),
              Text('Previous time: ${previous!.receivedAt}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriorityCards extends StatelessWidget {
  final DiffResult? diff;
  final List<TTRecord> latestRows;
  final void Function({
    required String title,
    required List<TTRecord> rows,
    required String emptyText,
  })
  onOpenRows;

  const _PriorityCards({
    required this.diff,
    required this.latestRows,
    required this.onOpenRows,
  });

  @override
  Widget build(BuildContext context) {
    List<TTRecord> matches(List<TTRecord> rows, String categoryContains) {
      return rows
          .where((row) => row.category.toLowerCase().contains(categoryContains))
          .toList();
    }

    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            title: 'Down Site',
            openRows: matches(latestRows, 'down site'),
            addedRows: matches(diff?.added ?? const <TTRecord>[], 'down site'),
            clearedRows: matches(
              diff?.cleared ?? const <TTRecord>[],
              'down site',
            ),
            onOpenRows: onOpenRows,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            title: 'Down Cell',
            openRows: matches(latestRows, 'down cell'),
            addedRows: matches(diff?.added ?? const <TTRecord>[], 'down cell'),
            clearedRows: matches(
              diff?.cleared ?? const <TTRecord>[],
              'down cell',
            ),
            onOpenRows: onOpenRows,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final List<TTRecord> openRows;
  final List<TTRecord> addedRows;
  final List<TTRecord> clearedRows;
  final void Function({
    required String title,
    required List<TTRecord> rows,
    required String emptyText,
  })
  onOpenRows;

  const _KpiCard({
    required this.title,
    required this.openRows,
    required this.addedRows,
    required this.clearedRows,
    required this.onOpenRows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => onOpenRows(
                title: '$title Open',
                rows: openRows,
                emptyText: 'No open TTs found for $title.',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${openRows.length}',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 2),
                  Text('Open', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CountChip(
                  label: 'Added',
                  value: addedRows.length,
                  tone: Colors.orange,
                  onPressed: () => onOpenRows(
                    title: '$title Added',
                    rows: addedRows,
                    emptyText: 'No added TTs found for $title.',
                  ),
                ),
                _CountChip(
                  label: 'Cleared',
                  value: clearedRows.length,
                  tone: Colors.green,
                  onPressed: () => onOpenRows(
                    title: '$title Cleared',
                    rows: clearedRows,
                    emptyText: 'No cleared TTs found for $title.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int value;
  final Color tone;
  final VoidCallback onPressed;

  const _CountChip({
    required this.label,
    required this.value,
    required this.tone,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: tone.withValues(alpha: 0.15),
        foregroundColor: tone,
        child: Text('$value'),
      ),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

class _OtherCounts extends StatelessWidget {
  final Map<String, int> counts;
  final List<TTRecord> latestRows;
  final void Function({
    required String title,
    required List<TTRecord> rows,
    required String emptyText,
  })
  onOpenRows;

  const _OtherCounts({
    required this.counts,
    required this.latestRows,
    required this.onOpenRows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (counts.isEmpty) return const SizedBox.shrink();
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('All categories', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final entry in entries)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(entry.key),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${entry.value}'),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => onOpenRows(
                  title: entry.key,
                  rows: latestRows
                      .where((row) => row.category == entry.key)
                      .toList(),
                  emptyText: 'No open TTs found for ${entry.key}.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
