import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    setState(() {
      _expenses = data;
    });
  }

  void _showAddExpenseDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    const Color primaryBrown = Color(0xFF3E2723);
    const Color accentGold = Color(0xFFD4AF37);
    const Color surfaceBeige = Color(0xFFF5E6D3);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: surfaceBeige,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [surfaceBeige, surfaceBeige.withOpacity(0.8)],
            ),
            border: Border.all(
              color: const Color(0xFFC62828).withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.money_off,
                  color: Color(0xFFC62828),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "تسجيل سحب / مصروف",
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: primaryBrown,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "المبلغ (دينار)",
                  labelStyle: GoogleFonts.cairo(
                    color: primaryBrown.withOpacity(0.7),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: accentGold, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: accentGold, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: accentGold, width: 2.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: "السبب (مثال: يومية عامل، ثلج..)",
                  labelStyle: GoogleFonts.cairo(
                    color: primaryBrown.withOpacity(0.7),
                  ),
                  prefixIcon: const Icon(Icons.description),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: accentGold, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: accentGold, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: accentGold, width: 2.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "إلغاء",
                        style: GoogleFonts.cairo(
                          color: primaryBrown,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62828),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (amountController.text.isNotEmpty &&
                            descController.text.isNotEmpty) {
                          await DatabaseHelper.instance.addExpense(
                            double.parse(amountController.text),
                            descController.text,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          _loadExpenses();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "تم تسجيل المصروف!",
                                style: GoogleFonts.cairo(),
                              ),
                              backgroundColor: Colors.orange,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Text(
                        "سحب من الصندوق",
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteExpense(int id) async {
    await DatabaseHelper.instance.deleteExpense(id);
    _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBrown = Color(0xFF3E2723);
    const Color accentGold = Color(0xFFD4AF37);
    const Color surfaceBeige = Color(0xFFF5E6D3);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "💰 المصروفات والسحوبات",
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFC62828),
        elevation: 8,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [surfaceBeige, surfaceBeige.withOpacity(0.7)],
          ),
        ),
        child: _expenses.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 80,
                      color: primaryBrown.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "لم يتم سحب أي مبالغ من الصندوق اليوم.",
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: primaryBrown.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _expenses.length,
                itemBuilder: (context, index) {
                  final exp = _expenses[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: const Color(0xFFC62828).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC62828).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.trending_down,
                                color: Color(0xFFC62828),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exp['description'],
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: primaryBrown,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "الوقت: ${exp['expense_date']}",
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: primaryBrown.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${exp['amount']} د",
                                  style: GoogleFonts.cairo(
                                    color: const Color(0xFFC62828),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(
                                  height: 32,
                                  width: 32,
                                  child: InkWell(
                                    onTap: () => _deleteExpense(exp['id']),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: primaryBrown.withOpacity(0.5),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFC62828),
        elevation: 12,
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.add_circle, size: 28),
        label: Text(
          "تسجيل مصروف",
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}