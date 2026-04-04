import 'dart:async';

import '../storage/storage.dart';
import '../storage/types.dart';

class AppState {
  final StreamController<void> _changes = StreamController.broadcast();
  Stream<void> get changes => _changes.stream;

  String? selectedGovernorate;
  String? selectedArea;

  AppSnapshot snapshot = const AppSnapshot.empty();

  void dispose() {
    _changes.close();
  }

  Future<void> refresh() async {
    snapshot = await Storage.buildSnapshot(
      selectedArea: selectedArea,
      selectedGovernorate: selectedGovernorate,
    );
    _changes.add(null);
  }

  Future<void> setGovernorate(String? governorate) async {
    selectedGovernorate = governorate;
    selectedArea = null;
    await refresh();
  }

  Future<void> setArea(String? area) async {
    selectedArea = area;
    await refresh();
  }
}
