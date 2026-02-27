import 'package:flutter/material.dart';

import '../services/database_helper.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Map<String, dynamic>> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() async {
    final data = await DatabaseHelper.instance.getExpenses();
    setState(() { _expenses = data; });
  }

  void _showAddExpenseDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تسجيل سحب / مصروف", style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "المبلغ (دينار)", icon: Icon(Icons.money, color: Colors.green))),
            const SizedBox(height: 10),
            TextField(controller: descController, decoration: const InputDecoration(labelText: "السبب (مثال: يومية عامل، ثلج..)", icon: Icon(Icons.edit, color: Colors.blue))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (amountController.text.isNotEmpty && descController.text.isNotEmpty) {
                await DatabaseHelper.instance.addExpense(double.parse(amountController.text), descController.text);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadExpenses();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تسجيل المصروف!"), backgroundColor: Colors.orange));
              }
            },
            child: const Text("سحب من الصندوق"),
          ),
        ],
      ),
    );
  }

  void _deleteExpense(int id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("المصروفات والسحوبات"), backgroundColor: Colors.red[300]),
      body: _expenses.isEmpty
          ? const Center(child: Text("لم يتم سحب أي مبالغ من الصندوق اليوم.", style: TextStyle(fontSize: 16)))
          : ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final exp = _expenses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.arrow_downward, color: Colors.white)),
                    title: Text(exp['description'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("الوقت: ${exp['expense_date']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${exp['amount']} دينار", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () => _deleteExpense(exp['id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red,
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.remove_circle),
        label: const Text("تسجيل مصروف"),
      ),
    );
  }
}