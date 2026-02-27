import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    const Color primaryBrown = Color(0xFF3E2723);
    const Color accentGold = Color(0xFFD4AF37);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFFF5E6D3),
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
                colors: [
                  const Color(0xFFF5E6D3),
                  const Color(0xFFE6D5BF),
                ],
              ),
              border: Border.all(color: accentGold.withOpacity(0.5), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock,
                    color: const Color(0xFFD32F2F),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "🔐 صلاحيات المدير",
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: primaryBrown,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                  decoration: InputDecoration(
                    labelText: "أدخل الرمز السري",
                    labelStyle: GoogleFonts.cairo(
                      color: primaryBrown.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: accentGold, width: 2),
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
                        onPressed: () => Navigator.pop(dialogContext),
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
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final savedPin = prefs.getString('system_pin') ?? "1234";

                          if (pinController.text == savedPin) {
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            Navigator.pop(context);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => targetScreen),
                            );
                            onRefresh();
                          } else {
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "الرمز السري خاطئ! غير مصرح لك بالدخول.",
                                  style: GoogleFonts.cairo(),
                                ),
                                backgroundColor: const Color(0xFFD32F2F),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Text(
                          "دخول",
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBrown = Color(0xFF3E2723);
    const Color accentGold = Color(0xFFD4AF37);
    const Color surfaceBeige = Color(0xFFF5E6D3);

    return Drawer(
      backgroundColor: surfaceBeige,
      child: ListView(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryBrown, Color(0xFF5D4037)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentGold, width: 2),
                  ),
                  child: const Icon(
                    Icons.dashboard,
                    color: accentGold,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "☕ لمة كافيه",
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "لوحة التحكم",
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: accentGold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDrawerItem(
            icon: Icons.money_off,
            iconColor: const Color(0xFFC62828),
            title: "المصروفات والسحوبات",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExpensesScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.fastfood,
            iconColor: const Color(0xFF1976D2),
            title: "إدارة المنتجات",
            onTap: () => _showPinDialog(context, const ProductsScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.category,
            iconColor: const Color(0xFF7B1FA2),
            title: "إدارة التصنيفات",
            onTap: () => _showPinDialog(context, const CategoriesScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.table_restaurant,
            iconColor: const Color(0xFF6D4C41),
            title: "إدارة الطاولات",
            onTap: () => _showPinDialog(context, const TableSettingsScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.sports_esports,
            iconColor: const Color(0xFF7B1FA2),
            title: "إدارة صالة الألعاب",
            onTap: () => _showPinDialog(context, const GamingSettingsScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.analytics,
            iconColor: const Color(0xFF388E3C),
            title: "الإحصائيات والفواتير",
            onTap: () => _showPinDialog(context, const StatisticsScreen()),
            isBold: true,
          ),
          _buildDrawerItem(
            icon: Icons.print,
            iconColor: const Color(0xFF455A64),
            title: "إعدادات الطابعات",
            onTap: () => _showPinDialog(context, const PrinterSettingsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool isBold = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: isBold ? 16 : 15,
                      fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                      color: const Color(0xFF2C2C2C),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: const Color(0xFF2C2C2C).withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
