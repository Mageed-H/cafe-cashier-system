import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/database_helper.dart';

// 🎨 Brand Colors
const Color primaryBrown = Color(0xFF3E2723);
const Color accentGold = Color(0xFFD4AF37);
const Color busyRed = Color(0xFFD32F2F);
const Color successGreen = Color(0xFF2E7D32);

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
        title: Text("تسجيل سحب / مصروف", 
          style: GoogleFonts.cairo(color: busyRed, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "المبلغ (دينار)", icon: Icon(Icons.money, color: successGreen))),
            const SizedBox(height: 10),
            TextField(controller: descController, decoration: const InputDecoration(labelText: "السبب (مثال: يومية عامل، ثلج..)", icon: Icon(Icons.edit, color: Color(0xFF1565C0)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: busyRed, 
              foregroundColor: Colors.white,
              animationDuration: const Duration(milliseconds: 300),
            ),
            onPressed: () async {
              if (amountController.text.isNotEmpty && descController.text.isNotEmpty) {
                await DatabaseHelper.instance.addExpense(double.parse(amountController.text), descController.text);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadExpenses();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تسجيل المصروف!"), backgroundColor: accentGold));
              }
            },
            child: Text("سحب من الصندوق", style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
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
      appBar: AppBar(title: Text("المصروفات والسحوبات", style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: Colors.white)), backgroundColor: busyRed),
      body: _expenses.isEmpty
          ? const Center(child: Text("لم يتم سحب أي مبالغ من الصندوق اليوم.", style: TextStyle(fontSize: 16)))
          : ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final exp = _expenses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: busyRed, child: Icon(Icons.arrow_downward, color: Colors.white)),
                    title: Text(exp['description'], style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    subtitle: Text("الوقت: ${exp['expense_date']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${exp['amount']} دينار", style: GoogleFonts.cairo(color: busyRed, fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () => _deleteExpense(exp['id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: busyRed,
        foregroundColor: Colors.white,
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.remove_circle),
        label: Text("تسجيل مصروف", style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        splashColor: Colors.white.withValues(alpha: 0.3),
      ),
    );
  }
}