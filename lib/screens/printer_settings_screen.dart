import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🎨 Brand Colors
const Color primaryBrown = Color(0xFF3E2723);
const Color accentGold = Color(0xFFD4AF37);
const Color successGreen = Color(0xFF2E7D32);

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  String? _chefPrinterName;
  String? _cashierPrinterName;

  @override
  void initState() {
    super.initState();
    _loadSavedPrinters();
  }

  // جلب أسماء الطابعات المحفوظة لعرضها للمستخدم
  void _loadSavedPrinters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _chefPrinterName =
          prefs.getString('chef_printer_name') ?? 'لم يتم التحديد';
      _cashierPrinterName =
          prefs.getString('cashier_printer_name') ?? 'لم يتم التحديد';
    });
  }

  // دالة اختيار الطابعة وحفظها (نحفظ المسار للبرمجة، والاسم للعرض)
  Future<void> _pickPrinter(String role, String urlKey, String nameKey) async {
    final printer =
        await Printing.pickPrinter(context: context, title: 'اختر الطابعة');

    if (printer != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(urlKey, printer.url);
      await prefs.setString(nameKey, printer.name);

      _loadSavedPrinters(); // تحديث الواجهة

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تعيين طابعة $role بنجاح!'),
            backgroundColor: successGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إعدادات الطابعات',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: accentGold,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            const Text(
              "حدد الطابعات الافتراضية للنظام حتى تتم الطباعة مباشرة بدون نوافذ منبثقة.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // 👇 بطاقة طابعة المطبخ (الشيف) 👇
            Card(
              elevation: 3,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepOrange,
                  child: Icon(Icons.soup_kitchen, color: Colors.white),
                ),
                title: const Text('طابعة المطبخ (الشيف)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_chefPrinterName ?? 'جاري التحميل...'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    animationDuration: const Duration(milliseconds: 300),
                  ),
                  onPressed: () => _pickPrinter(
                      'المطبخ', 'chef_printer_url', 'chef_printer_name'),
                  child: const Text('تغيير'),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 👇 بطاقة طابعة الكاشير (الزبون) 👇
            Card(
              elevation: 3,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.receipt_long, color: Colors.white),
                ),
                title: const Text('طابعة الكاشير (الزبون)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_cashierPrinterName ?? 'جاري التحميل...'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    animationDuration: const Duration(milliseconds: 300),
                  ),
                  onPressed: () => _pickPrinter(
                      'الكاشير', 'cashier_printer_url', 'cashier_printer_name'),
                  child: const Text('تغيير'),
                ),
              ),
            ),

            const Spacer(),
            // زر لإلغاء الطابعات في حال أراد الكاشير إرجاع نافذة الطباعة العادية
            TextButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('chef_printer_url');
                await prefs.remove('chef_printer_name');
                await prefs.remove('cashier_printer_url');
                await prefs.remove('cashier_printer_name');
                _loadSavedPrinters();
              },
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('إلغاء الطابعات الافتراضية',
                  style: TextStyle(color: Colors.red)),
            )
          ],
        ),
      ),
    );
  }
}
