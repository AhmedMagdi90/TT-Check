import 'package:flutter/material.dart';

import 'state/app_state.dart';
import 'ui/home_shell.dart';

class TTCheckApp extends StatefulWidget {
  const TTCheckApp({super.key});

  @override
  State<TTCheckApp> createState() => _TTCheckAppState();
}

class _TTCheckAppState extends State<TTCheckApp> {
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = AppState()..refresh();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TT Check',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B4965)),
      ),
      home: HomeShell(state: _state),
    );
  }
}

