import 'dart:async';

import '../storage/storage.dart';
import '../storage/types.dart';

class AppState {
  final StreamController<void> _changes = StreamController.broadcast();
  Stream<void> get changes => _changes.stream;

  String? selectedArea;

  AppSnapshot snapshot = const AppSnapshot.empty();

  void dispose() {
    _changes.close();
  }

  Future<void> refresh() async {
    snapshot = await Storage.buildSnapshot(selectedArea: selectedArea);
    _changes.add(null);
  }

  Future<void> setArea(String? area) async {
    selectedArea = area;
    await refresh();
  }
}

