import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/expence_filter.dart';
import 'models/expense.dart';
import 'services/github_service.dart';
import 'services/sync_service.dart';
import 'services/hive_service.dart';

/// Providers for GitHub sync and syncing service
final githubProvider = Provider((ref) => GithubService());
final syncServiceProvider =
Provider((ref) => SyncService(ref.read(githubProvider)));



/// Provider for list of expenses
final expensesProvider =
StateNotifierProvider<ExpensesNotifier, List<Expense>>((ref) {
  return ExpensesNotifier(ref);
});

final expenseFilterProvider = StateProvider<ExpenseFilter>((ref) => ExpenseFilter(membersIncluded:  ["Rahul", "Raushan", "Ijhar"],));

final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final allExpenses = ref.watch(expensesProvider);
  final filter = ref.watch(expenseFilterProvider);

  return allExpenses.where((e) {
    // 1️⃣ Paid by filter
    if (filter.paidBy != null &&
        filter.paidBy!.isNotEmpty &&
        e.paidBy != filter.paidBy) {
      return false;
    }

    // 2️⃣ Shared between filter (supports exact combinations or subset)
    if (filter.membersIncluded != null && filter.membersIncluded!.isNotEmpty) {
      final shared = e.sharedBetween ?? [];

      // Option A: Must include all selected members (subset)
      // final containsAllSelected = filter.membersIncluded!
      //     .every((member) => shared.contains(member));

     // Option B: Exact match (sharedBetween == selectedMembers)
      final containsAllSelected = filter.membersIncluded!
          .every((member) => shared.contains(member)) &&
          shared.length == filter.membersIncluded!.length;

      if (!containsAllSelected) {
        return false;
      }
    }

    // 3️⃣ Date filter
    final expDate = DateTime.tryParse(e.date);
    if (expDate != null) {
      if (filter.fromDate != null && expDate.isBefore(filter.fromDate!)) {
        return false;
      }
      if (filter.toDate != null && expDate.isAfter(filter.toDate!)) {
        return false;
      }
    }

    return true;
  }).toList();
});


// class ExpensesNotifier extends StateNotifier<List<Expense>> {
//   final Ref ref;
//
//   ExpensesNotifier(this.ref) : super([]) {
//     _loadFromLocal();
//   }
//
//   void _loadFromLocal() async {
//     final local = HiveService.readLocal();
//
//     if (local == null || local['expenses'] == null) {
//       // Fetch from GitHub if local data is missing
//       try {
//         final remote = await ref.read(syncServiceProvider).github.fetchRawJson();
//         await HiveService.writeLocal(remote);
//
//         final expensesList = (remote['expenses'] as List)
//             .map((e) => Expense.fromJson(Map<String, dynamic>.from(e)))
//             .toList();
//         state = expensesList;
//       } catch (e) {
//         state = [];
//       }
//       return;
//     }
//
//     try {
//       final expensesList = (local['expenses'] as List)
//           .map((e) => Expense.fromJson(Map<String, dynamic>.from(e)))
//           .toList();
//       state = expensesList;
//     } catch (e) {
//       state = [];
//     }
//   }
//
//
//   Future<void> addExpense(Expense e) async {
//     // Update provider state
//     state = [...state, e];
//
//     // Read full local JSON
//     final local = HiveService.readLocal() ?? {
//       'members': [],
//       'expenses': [],
//       'updated_at': DateTime.now().toIso8601String(),
//     };
//
//     // Update expenses
//     final existing = List.from(local['expenses'] as List);
//     existing.add(e.toJson());
//     local['expenses'] = existing;
//
//     // Update timestamp
//     local['updated_at'] = DateTime.now().toIso8601String();
//
//     // Save to Hive
//     await HiveService.writeLocal(local);
//
//     // Sync safely
//     await ref.read(syncServiceProvider).addExpense(e.toJson());
//   }
//
//
//   Future<void> refreshFromRemote() async {
//     try {
//       await ref.read(syncServiceProvider).sync();
//     } catch (e) {
//       // Handle errors if GitHub is not reachable
//       print("GitHub fetch failed: $e");
//     }
//     _loadFromLocal();
//   }
//
// }

class ExpensesNotifier extends StateNotifier<List<Expense>> {
  final Ref ref;

  ExpensesNotifier(this.ref) : super([]) {
    _initialize();
    // Background sync
    final githubService = GithubService();
    final syncService = SyncService(githubService);

    syncService.sync().then((_) {
      // reload after merge
      _loadFromLocal();
    }).catchError((e) {
      print('GitHub sync failed: $e');
    });
  }

  Future<void> _initialize() async {
    try {
      // 1️⃣ Sync data from GitHub and merge with local
      await ref.read(syncServiceProvider).sync();

      // 2️⃣ Load merged data from local Hive
      _loadFromLocal();
    } catch (e) {
      print('Failed to initialize expenses: $e');
      _loadFromLocal(); // fallback to local data if sync fails
    }
  }

  void _loadFromLocal() {
    final local = HiveService.readLocal();

    if (local == null || local['expenses'] == null) {
      state = [];
      return;
    }

    try {
      final expensesList = (local['expenses'] as List)
          .map((e) => Expense.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      state = expensesList;
    } catch (e) {
      state = [];
    }
  }

  Future<void> addExpense(Expense e) async {
    // 1️⃣ Add locally
    state = [...state, e];
    final jsonList = state.map((x) => x.toJson()).toList();

    final local = HiveService.readLocal() ?? {'members': [], 'expenses': [], 'updated_at': DateTime.now().toIso8601String()};
    local['expenses'] = jsonList;
    local['updated_at'] = DateTime.now().toIso8601String();

    await HiveService.writeLocal(local);

    // 2️⃣ Sync with GitHub
    try {
      await ref.read(syncServiceProvider).sync();
    } catch (e) {
      print('GitHub sync failed: $e');
    }
  }

  Future<void> refreshFromRemote() async {
    try {
      await ref.read(syncServiceProvider).sync();
      _loadFromLocal();
    } catch (e) {
      print('Failed to refresh from remote: $e');
    }
  }
}
