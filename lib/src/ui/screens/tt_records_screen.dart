import 'package:flutter/material.dart';

import '../../storage/types.dart';
import '../widgets/tt_record_list.dart';

class TTRecordsScreen extends StatelessWidget {
  final String title;
  final List<TTRecord> rows;
  final String emptyText;

  const TTRecordsScreen({
    super.key,
    required this.title,
    required this.rows,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: TTRecordList(rows: rows, emptyText: emptyText),
    );
  }
}
