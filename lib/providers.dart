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


class ExpensesNotifier extends StateNotifier<List<Expense>> {
  final Ref ref;

  ExpensesNotifier(this.ref) : super([]) {
    _loadFromLocal();
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
    state = [...state, e];
    final jsonList = state.map((x) => x.toJson()).toList();
    await HiveService.writeLocal({'expenses': jsonList});
    await ref.read(syncServiceProvider).addExpense(e.toJson());
  }

  Future<void> refreshFromRemote() async {
    await ref.read(syncServiceProvider).sync();
    _loadFromLocal();
  }
}
