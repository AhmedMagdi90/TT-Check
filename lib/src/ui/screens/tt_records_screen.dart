import 'package:flutter/material.dart';

import '../../storage/types.dart';
import '../widgets/tt_record_explorer.dart';

class TTRecordsScreen extends StatelessWidget {
  final String title;
  final List<TTRecord> rows;
  final String emptyText;
  final List<TTExplorerInfo> info;

  const TTRecordsScreen({
    super.key,
    required this.title,
    required this.rows,
    required this.emptyText,
    this.info = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: TTRecordExplorer(
        title: title,
        rows: rows,
        emptyText: emptyText,
        info: info,
      ),
    );
  }
}
