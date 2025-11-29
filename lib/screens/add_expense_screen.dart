import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  String _paidBy = 'Rahul';

  List<String> members = ["Rahul", "Raushan", "Ijhar"];
  List<String> selectedMembers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _itemCtrl,
                  decoration: const InputDecoration(labelText: 'Item'),
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
                ),

                TextFormField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                  v == null || double.tryParse(v) == null
                      ? 'Enter amount'
                      : null,
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _paidBy,
                  items: members
                      .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ))
                      .toList(),
                  onChanged: (v) => setState(() => _paidBy = v!),
                  decoration: const InputDecoration(labelText: 'Paid by'),
                ),

                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Shared Between",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                Column(
                  children: members.map((m) {
                    return CheckboxListTile(
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
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    if (selectedMembers.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Select at least 1 member"),
                        ),
                      );
                      return;
                    }

                    final id = const Uuid().v4();

                    final e = Expense(
                      id: id,
                      item: _itemCtrl.text.trim(),
                      amount: double.parse(_amountCtrl.text.trim()),
                      paidBy: _paidBy,
                      sharedBetween: selectedMembers,
                      date: DateTime.now().toIso8601String().split('T').first,
                    );
                    await ref.read(expensesProvider.notifier).addExpense(e);

                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
