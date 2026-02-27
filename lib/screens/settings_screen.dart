import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  // 👇 1. ضفنا متحكم جديد لأرقام الهواتف 👇
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pinController.text = prefs.getString('system_pin') ?? "1234";
      _nameController.text = prefs.getString('cafe_name') ?? "لمة كافيه";
      // 👇 2. جلب أرقام الهواتف المحفوظة 👇
      _phoneController.text = prefs.getString('cafe_phones') ?? "";
    });
  }

  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('system_pin', _pinController.text.trim());
    await prefs.setString('cafe_name', _nameController.text.trim());
    // 👇 3. حفظ أرقام الهواتف بالذاكرة 👇
    await prefs.setString('cafe_phones', _phoneController.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("تم حفظ الإعدادات بنجاح!"),
        backgroundColor: Colors.green));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("الإعدادات المخفية 🔒"),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "هذه الشاشة مخصصة لمدير النظام فقط.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 2),
            const SizedBox(height: 15),

            const Text("إعدادات الأمان",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "الرمز السري الجديد (PIN)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.password, color: Colors.blue),
              ),
            ),

            const SizedBox(height: 25),

            const Text("إعدادات الفاتورة",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "اسم الكافتريا (يظهر في أعلى الطباعة)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store, color: Colors.green),
              ),
            ),

            const SizedBox(height: 15),

            // 👇 4. مربع إضافة أرقام الهواتف 👇
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "أرقام الهواتف (تظهر أسفل الطباعة)",
                hintText: "مثال: 07700000000 - 07800000000",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone, color: Colors.orange),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text("حفظ التغييرات",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
