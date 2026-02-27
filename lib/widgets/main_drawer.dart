import 'package:flutter/material.dart';
import '../screens/table_settings_screen.dart';
import '../screens/products_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/expenses_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/gaming_settings_screen.dart';
import '../screens/printer_settings_screen.dart';

class MainDrawer extends StatelessWidget {
  final VoidCallback onRefresh;

  const MainDrawer({required this.onRefresh, super.key});

  void _showPinDialog(BuildContext context, Widget targetScreen) {
    final TextEditingController pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("صلاحيات المدير 🔒",
              style: TextStyle(color: Colors.red)),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: "أدخل الرمز السري", border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("إلغاء")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final savedPin = prefs.getString('system_pin') ?? "1234";

                if (pinController.text == savedPin) {
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  Navigator.pop(context); // نسد الـ Drawer
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (context) => targetScreen));
                  onRefresh();
                } else {
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("الرمز السري خاطئ! غير مصرح لك بالدخول."),
                        backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text("دخول"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.orange),
            child: Center(
                child: Text("لوحة التحكم",
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold))),
          ),

          ListTile(
            leading: const Icon(Icons.money_off, color: Colors.red),
            title: const Text("المصروفات والسحوبات"),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ExpensesScreen()));
            },
          ),

          ListTile(
            leading: const Icon(Icons.fastfood, color: Colors.blue),
            title: const Text("إدارة المنتجات "),
            onTap: () => _showPinDialog(context, const ProductsScreen()),
          ),

          ListTile(
            leading: const Icon(Icons.category, color: Colors.purple),
            title: const Text("إدارة التصنيفات"),
            onTap: () => _showPinDialog(context, const CategoriesScreen()),
          ),

          ListTile(
            leading: const Icon(Icons.table_restaurant, color: Colors.brown),
            title: const Text("إدارة الطاولات"),
            onTap: () => _showPinDialog(context, const TableSettingsScreen()),
          ),

          ListTile(
            leading: const Icon(Icons.sports_esports, color: Colors.purple),
            title: const Text("إدارة صالة الألعاب"),
            onTap: () => _showPinDialog(context, const GamingSettingsScreen()),
          ),

          ListTile(
            leading: const Icon(Icons.analytics, color: Colors.green),
            title: const Text("الإحصائيات والفواتير",
                style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => _showPinDialog(context, const StatisticsScreen()),
          ),

          // 👇 قفلنا إعدادات الطابعات حتى الكاشير ما يغيرها بالغلط 👇
          ListTile(
            leading: const Icon(Icons.print, color: Colors.blueGrey),
            title: const Text('إعدادات الطابعات'),
            onTap: () => _showPinDialog(context, const PrinterSettingsScreen()),
          ),
        ],
      ),
    );
  }
}
