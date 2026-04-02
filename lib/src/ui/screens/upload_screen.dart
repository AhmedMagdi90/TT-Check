import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../importing/excel_import.dart';
import '../../state/app_state.dart';
import '../../storage/storage.dart';

class UploadScreen extends StatefulWidget {
  final AppState state;
  const UploadScreen({super.key, required this.state});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _busy = false;
  String? _status;

  Future<void> _pickAndImportSiteCount() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
      withData: true,
    );
    final f = res?.files.single;
    if (f == null) return;
    final bytes = f.bytes ?? await File(f.path!).readAsBytes();

    setState(() {
      _busy = true;
      _status = 'Importing Site Count...';
    });
    try {
      final sites = ExcelImport.parseSiteCount(bytes);
      await Storage.upsertSites(sites);
      _status = 'Imported ${sites.length} sites.';
      await widget.state.refresh();
    } catch (e) {
      _status = 'Failed to import Site Count: $e';
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _pickAndImportTTReport() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
      withData: true,
    );
    final f = res?.files.single;
    if (f == null) return;
    final bytes = f.bytes ?? await File(f.path!).readAsBytes();

    setState(() {
      _busy = true;
      _status = 'Importing TT report...';
    });
    try {
      final batch = await Storage.createBatch(fileName: f.name);
      final rows = ExcelImport.parseTTReport(bytes);
      await Storage.putBatchRows(batch.id, rows);
      _status = 'Imported ${rows.length} TT rows in batch ${batch.receivedAt}.';
      await widget.state.refresh();
    } catch (e) {
      _status = 'Failed to import TT report: $e';
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Upload')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : _pickAndImportSiteCount,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Upload Site Count (Area mapping)'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _pickAndImportTTReport,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Upload TT Report (hourly)'),
            ),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Text(_status!, style: theme.textTheme.bodyMedium),
            ],
            const Spacer(),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'MVP notes:\n'
                  '- Compare works after 2 uploads.\n'
                  '- Down Site / Down Cell are highlighted on Dashboard.\n'
                  '- Area filter depends on matching TT “Node” to Site Count “SiteName”.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

