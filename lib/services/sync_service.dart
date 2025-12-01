import 'package:flutter/foundation.dart';
import '../services/github_service.dart';
import '../services/hive_service.dart';
import 'package:uuid/uuid.dart';

class SyncService {
  final GithubService github;
  final _uuid = const Uuid();

  SyncService(this.github);

  /// Sync local and remote data safely.
  /// Handles multi-device updates by merging expenses.
  Future<void> sync() async {
    try {
      final remote = await github.fetchRawJson();
      final local = HiveService.readLocal();

      Map<String, dynamic> merged;

      if (local == null) {
        // First time install, just save remote
        merged = remote;
      } else {
        // Merge expenses
        final localExpenses = List<Map<String, dynamic>>.from(local['expenses'] ?? []);
        final remoteExpenses = List<Map<String, dynamic>>.from(remote['expenses'] ?? []);

        // Merge without duplicates (using unique id)
        final mergedExpenses = [
          ...localExpenses,
          ...remoteExpenses.where((r) =>
          !localExpenses.any((l) => l['id'] == r['id']))
        ];

        merged = {
          ...remote,
          'expenses': mergedExpenses,
          'updated_at': DateTime.now().toIso8601String(),
        };
      }

      // Save merged data locally
      await HiveService.writeLocal(merged);

      // Push merged data to GitHub
      try {
        await github.updateFile(merged);
        if (kDebugMode) print('GitHub push successful');
      } catch (e) {
        if (kDebugMode) print('GitHub push failed: $e');
      }

    } catch (e) {
      if (kDebugMode) print('GitHub fetch failed: $e');
    }
  }

  /// Add new expense safely
  Future<void> addExpense(Map<String, dynamic> expenseJson) async {
    final local = HiveService.readLocal() ?? {
      'members': [],
      'expenses': [],
      'updated_at': DateTime.now().toIso8601String(),
    };

    final List<Map<String, dynamic>> expenses =
    List<Map<String, dynamic>>.from(local['expenses'] ?? []);

    // Assign unique ID if not present
    if (!expenseJson.containsKey('id')) {
      expenseJson['id'] = _uuid.v4();
    }

    expenses.add(expenseJson);
    local['expenses'] = expenses;
    local['updated_at'] = DateTime.now().toIso8601String();

    // Save locally
    await HiveService.writeLocal(local);

    // Sync with GitHub
    await sync();
  }
}
