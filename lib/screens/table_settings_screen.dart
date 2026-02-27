import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_helper.dart';

// 🎨 Brand Colors
const Color primaryBrown = Color(0xFF3E2723);
const Color accentGold = Color(0xFFD4AF37);
const Color busyRed = Color(0xFFD32F2F);
const Color successGreen = Color(0xFF2E7D32);

class TableSettingsScreen extends StatefulWidget {
  const TableSettingsScreen({super.key});

  @override
  State<TableSettingsScreen> createState() => _TableSettingsScreenState();
}

class _TableSettingsScreenState extends State<TableSettingsScreen> {
  final TextEditingController _tableController = TextEditingController();
  List<Map<String, dynamic>> _tables = [];

  @override
  void initState() {
    super.initState();
    _refreshTables();
  }

  void _refreshTables() async {
    final data = await DatabaseHelper.instance.getTables();
    setState(() {
      _tables = data;
    });
  }

  void _addTable() async {
    if (_tableController.text.isEmpty) return;

    int newTableNumber = int.parse(_tableController.text);

    // 👇 الفحص الذكي: هل الطاولة موجودة مسبقاً بقاعدة البيانات؟ 👇
    bool isDuplicate = _tables.any((table) => table['table_number'] == newTableNumber);

    if (isDuplicate) {
      // إظهار رسالة خطأ للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("عذراً، طاولة رقم ($newTableNumber) موجودة مسبقاً!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return; // نوقف التنفيذ حتى لا تنضاف للـ Database
    }

    // إذا ماكو تكرار، نضيفها براحتنا
    await DatabaseHelper.instance.addTable(newTableNumber);
    _tableController.clear();
    _refreshTables();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("إدارة الطاولات",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryBrown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ================= حقل إضافة طاولة جديدة =================
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tableController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "رقم الطاولة",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.table_restaurant, color: Colors.orange),
                    ),
                    onSubmitted: (_) => _addTable(), // حتى يضيف من يدوس Enter بالكيبورد
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBrown,
                      foregroundColor: Colors.white,
                      animationDuration: const Duration(milliseconds: 300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _addTable,
                    icon: const Icon(Icons.add),
                    label: Text("إضافة", 
                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            const Divider(thickness: 2),
            const SizedBox(height: 10),

            // ================= شبكة عرض الطاولات (GridView) =================
            Expanded(
              child: _tables.isEmpty
                  ? const Center(
                      child: Text(
                        "لا توجد طاولات مضافة حالياً.",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6, // عدد الطاولات بالسطر الواحد (مناسب للويندوز)
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.2, // تتحكم بعرض وارتفاع المربع
                      ),
                      itemCount: _tables.length,
                      itemBuilder: (context, index) {
                        final table = _tables[index];
                        return Card(
                          color: Colors.orange[50],
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.orange[300]!, width: 1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              // رقم الطاولة بالوسط
                              Center(
                                child: Text(
                                  "طاولة\n${table['table_number']}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              // زر الحذف بالزاوية العلوية
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  tooltip: "حذف الطاولة",
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await DatabaseHelper.instance.deleteTable(table['id']);
                                    _refreshTables();
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}