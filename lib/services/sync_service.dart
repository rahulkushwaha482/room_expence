import 'package:uuid/uuid.dart';
import '../services/github_service.dart';
import '../services/hive_service.dart';

class SyncService {
  final GithubService github;

  SyncService(this.github);

  /// Simple merge strategy: last-writer-wins using updated_at
  Future<void> sync() async {
    try {
      final remote = await github.fetchRawJson();
      final local = HiveService.readLocal();

      if (local == null) {
        // no local data, just store remote locally
        await HiveService.writeLocal(remote);
        return;
      }

      final remoteUpdated = DateTime.tryParse(remote['updated_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final localUpdated = DateTime.tryParse(local['updated_at'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

      Map<String, dynamic> merged;

      if (localUpdated.isAfter(remoteUpdated)) {
        // Push local to remote
        merged = local;
        merged['updated_at'] = DateTime.now().toIso8601String();
        await github.updateFile(merged, commitMessage: 'Sync from app (local newer)');
      } else if (remoteUpdated.isAfter(localUpdated)) {
        // Pull remote to local
        merged = remote;
        await HiveService.writeLocal(merged);
      } else {
        // same timestamp, keep remote as source of truth
        merged = remote;
        await HiveService.writeLocal(merged);
      }
    } catch (e) {
      // network or other error: rethrow for caller to handle
      rethrow;
    }
  }

  // Helper to add an expense locally and mark updated_at
  Future<void> addExpense(Map<String, dynamic> expenseJson) async {
    final local = HiveService.readLocal() ?? {'members': [], 'expenses': [], 'updated_at': DateTime.now().toIso8601String()};
    final List expenses = List.from(local['expenses'] as List);
    expenses.add(expenseJson);
    local['expenses'] = expenses;
    local['updated_at'] = DateTime.now().toIso8601String();
    await HiveService.writeLocal(local);
  }
}
