import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expence_filter.dart';
import '../providers.dart';
import '../models/expense.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(filteredExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Summary"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, ref),
          ),
        ],
      ),
      body: expenses.isEmpty
          ? const Center(child: Text('No expenses added yet'))
          : ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          // Reverse list to show latest first
          final e = expenses[expenses.length - 1 - index];
          return _buildExpenseCard(e);
        },
      ),
    );
  }

  // Widget to display each expense in a card
  Widget _buildExpenseCard(Expense e) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ListTile(
        title: Text(e.item),
        subtitle: Text('${e.paidBy} • ${e.date}'),
        trailing: Text('₹${e.amount.toStringAsFixed(2)}'),
      ),
    );
  }

  // Filter dialog refactored
  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    List<String> members = ["Rahul", "Raushan", "Ijhar"];

    String? paidBy = ref.read(expenseFilterProvider).paidBy;
    List<String> selectedMembers =
    List.from(ref.read(expenseFilterProvider).membersIncluded ?? []);
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
                  // Paid by dropdown
                  DropdownButtonFormField<String>(
                    value: paidBy,
                    decoration: const InputDecoration(labelText: "Paid by"),
                    items: [null, ...members]
                        .map(
                          (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e ?? "All"),
                      ),
                    )
                        .toList(),
                    onChanged: (v) => setState(() => paidBy = v),
                  ),
                  const SizedBox(height: 16),

                  // Shared between checkboxes
                  const Text(
                    "Shared Between",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...members.map(
                        (m) => CheckboxListTile(
                      title: Text(m),
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
                  const SizedBox(height: 16),

                  // Date pickers
                  Row(
                    children: [
                      _buildDateButton(
                        context,
                        label: "From",
                        date: fromDate,
                        onDateSelected: (d) => setState(() => fromDate = d),
                      ),
                      const SizedBox(width: 16),
                      _buildDateButton(
                        context,
                        label: "To",
                        date: toDate,
                        onDateSelected: (d) => setState(() => toDate = d),
                      ),
                    ],
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
          TextButton(
            onPressed: () {
              // Clear filters
              ref.read(expenseFilterProvider.notifier).state = ExpenseFilter();
              Navigator.pop(context);
            },
            child: const Text("Clear"),
          ),
        ],
      ),
    );
  }

  // Helper for date picker buttons
  Widget _buildDateButton(
      BuildContext context, {
        required String label,
        required DateTime? date,
        required void Function(DateTime) onDateSelected,
      }) {
    return TextButton(
      onPressed: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) onDateSelected(pickedDate);
      },
      child: Text(
        date != null ? date.toLocal().toString().split(' ')[0] : label,
      ),
    );
  }
}
