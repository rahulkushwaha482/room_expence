import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expence_filter.dart';
import '../providers.dart';
import 'add_expense_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {


    return Scaffold(
      appBar: AppBar(
        title: const Text('Roommate Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              try {
                await ref.read(expensesProvider.notifier).refreshFromRemote();
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Synced')));
              } catch (e) {
                print('e.toString()');
                print(e.toString());
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Sync failed: $e')));
              }
            },
          ),

          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, ref),
          ),

        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(ref),

          Row(children: [
            ElevatedButton(onPressed: (){
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SummaryScreen()));
            }, child: Text('See Expences'))
          ],),

        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'add',
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
            },
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    List<String> members = ["Rahul", "Raushan", "Ijhar"];

    String? paidBy = ref.read(expenseFilterProvider).paidBy;
    List<String> selectedMembers =
    List.from(ref.read(expenseFilterProvider).membersIncluded ?? []);
    if (selectedMembers.isEmpty) {
      selectedMembers = List.from(members);
    }

    DateTime? fromDate = ref.read(expenseFilterProvider).fromDate;
    DateTime? toDate = ref.read(expenseFilterProvider).toDate;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Filter Expenses"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Shared Between",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...members.map(
                        (m) => CheckboxListTile(
                      title: Text(m),
                      selected: true,
                      value: selectedMembers.contains(m),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            selectedMembers.add(m);
                          } else {
                            selectedMembers.remove(m);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Apply filters
              ref.read(expenseFilterProvider.notifier).state = ExpenseFilter(
                paidBy: paidBy,
                membersIncluded:
                selectedMembers.isNotEmpty ? selectedMembers : null,
                fromDate: fromDate,
                toDate: toDate,
              );
              Navigator.pop(context);
            },
            child: const Text("Apply"),
          ),

        ],
      ),
    );
  }


  Widget _buildSummaryCard(WidgetRef ref) {
    final expenses = ref.watch(filteredExpensesProvider);

    // 1️⃣ Collect all members dynamically
    final Set<String> allMembers = {};
    for (var e in expenses) {
      allMembers.addAll(e.sharedBetween);
      allMembers.add(e.paidBy);
    }

    // 2️⃣ Initialize maps
    final Map<String, double> totalPaid = {for (var m in allMembers) m: 0.0};
    final Map<String, double> totalShare = {for (var m in allMembers) m: 0.0};
    final Map<String, double> balances = {for (var m in allMembers) m: 0.0};

    // 3️⃣ Calculate totals and balances dynamically
    for (var e in expenses) {
      final splitAmount = e.amount / e.sharedBetween.length;

      // Total paid
      totalPaid[e.paidBy] = (totalPaid[e.paidBy] ?? 0) + e.amount;

      // Total share per member
      for (var member in e.sharedBetween) {
        totalShare[member] = (totalShare[member] ?? 0) + splitAmount;

        // Balances
        if (member != e.paidBy) {
          balances[member] = (balances[member] ?? 0) - splitAmount;
          balances[e.paidBy] = (balances[e.paidBy] ?? 0) + splitAmount;
        }
      }
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Total Paid Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Total paid per member
            ...totalPaid.entries.map(
                  (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontSize: 16)),
                    Text(
                      "₹${e.value.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 20),

            // Total share per member
            const Text(
              "Total Amount per Person",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...totalShare.entries.map(
                  (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key),
                    Text("₹${e.value.toStringAsFixed(2)}"),
                  ],
                ),
              ),
            ),

            const Divider(height: 20),

            // Balances
            const Text(
              "Balances",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...balances.entries.map((entry) {
              final name = entry.key;
              final amount = entry.value;
              String text;
              if (amount > 0) {
                text = "$name should receive ₹${amount.toStringAsFixed(2)}";
              } else if (amount < 0) {
                text = "$name pay ₹${(-amount).toStringAsFixed(2)}";
              } else {
                text = "$name is settled up";
              }
              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(text),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

}
