import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../storage/types.dart';

class DashboardScreen extends StatelessWidget {
  final AppState state;
  const DashboardScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: state.changes,
      builder: (context, _) {
        final snap = state.snapshot;
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('TT Check'),
              actions: [
                _AreaMenu(
                  areas: snap.areas,
                  selected: state.selectedArea,
                  onSelected: (a) => state.setArea(a),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () => state.refresh(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _BatchInfo(latest: snap.latestBatch, previous: snap.previousBatch),
                  const SizedBox(height: 12),
                  _PriorityCards(diff: snap.diff, counts: snap.latestCountsByCategory),
                  const SizedBox(height: 12),
                  _OtherCounts(counts: snap.latestCountsByCategory),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AreaMenu extends StatelessWidget {
  final List<String> areas;
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _AreaMenu({
    required this.areas,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      tooltip: 'Area filter',
      initialValue: selected,
      onSelected: onSelected,
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: null,
          checked: selected == null,
          child: const Text('All areas'),
        ),
        const PopupMenuDivider(),
        for (final a in areas)
          CheckedPopupMenuItem(
            value: a,
            checked: selected?.toLowerCase() == a.toLowerCase(),
            child: Text(a),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.place_outlined),
            const SizedBox(width: 6),
            Text(selected ?? 'All'),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, size: 18),
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
            'No TT batches yet. Go to Upload → “Upload TT Report”.',
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
              Text('Previous: ${previous!.receivedAt}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriorityCards extends StatelessWidget {
  final DiffResult? diff;
  final Map<String, int> counts;
  const _PriorityCards({required this.diff, required this.counts});

  @override
  Widget build(BuildContext context) {
    int count(String categoryContains) {
      final entry = counts.entries.firstWhere(
        (e) => e.key.toLowerCase().contains(categoryContains),
        orElse: () => const MapEntry('', 0),
      );
      return entry.value;
    }

    int added(String contains) =>
        diff?.added.where((r) => r.category.toLowerCase().contains(contains)).length ?? 0;
    int cleared(String contains) =>
        diff?.cleared.where((r) => r.category.toLowerCase().contains(contains)).length ?? 0;

    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            title: 'Down Site',
            open: count('down site'),
            added: added('down site'),
            cleared: cleared('down site'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            title: 'Down Cell',
            open: count('down cell'),
            added: added('down cell'),
            cleared: cleared('down cell'),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final int open;
  final int added;
  final int cleared;

  const _KpiCard({
    required this.title,
    required this.open,
    required this.added,
    required this.cleared,
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
            Text('Open: $open', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(label: 'Added', value: added, tone: Colors.orange),
                _Chip(label: 'Cleared', value: cleared, tone: Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int value;
  final Color tone;
  const _Chip({required this.label, required this.value, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.25)),
      ),
      child: Text('$label: $value'),
    );
  }
}

class _OtherCounts extends StatelessWidget {
  final Map<String, int> counts;
  const _OtherCounts({required this.counts});

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
            for (final e in entries)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(e.key),
                trailing: Text('${e.value}'),
              ),
          ],
        ),
      ),
    );
  }
}

