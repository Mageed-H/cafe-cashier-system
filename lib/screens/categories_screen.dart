import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_helper.dart';

// 🎨 Brand Colors
const Color accentGold = Color(0xFFD4AF37);
const Color gamingPurple = Color(0xFF7B1FA2);
const Color editBlue = Color(0xFF1565C0);
const Color deleteRed = Color(0xFFC62828);
const Color successGreen = Color(0xFF2E7D32);

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // جلب التصنيفات من قاعدة البيانات
  void _loadCategories() async {
    final cats = await DatabaseHelper.instance.getCategories();
    setState(() {
      _categories = cats;
    });
  }

  // دالة إضافة تصنيف جديد
  void _showAddCategoryDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("إضافة تصنيف جديد", 
          style: GoogleFonts.cairo(color: gamingPurple, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "اسم التصنيف",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category, color: gamingPurple),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: successGreen, 
              foregroundColor: Colors.white,
              animationDuration: const Duration(milliseconds: 300),
            ),
            onPressed: () async {
              String newCat = controller.text.trim();
              if (newCat.isNotEmpty) {
                int result = await DatabaseHelper.instance.addCategory(newCat);
                if (!context.mounted) return;
                Navigator.pop(context);
                
                if (result == -1) {
                  // معناها التصنيف موجود مسبقاً (Unique Constraint)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("هذا التصنيف موجود مسبقاً!"), backgroundColor: deleteRed),
                  );
                } else {
                  _loadCategories(); // تحديث الشاشة
                }
              }
            },
            child: Text("حفظ", style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // دالة تعديل اسم التصنيف
  void _showEditCategoryDialog(String oldName) {
    final TextEditingController controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("تعديل التصنيف", 
          style: GoogleFonts.cairo(color: editBlue, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "الاسم الجديد",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit, color: editBlue),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: editBlue, 
              foregroundColor: Colors.white,
              animationDuration: const Duration(milliseconds: 300),
            ),
            onPressed: () async {
              String newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                await DatabaseHelper.instance.updateCategory(oldName, newName);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadCategories();
              }
            },
            child: Text("تحديث", style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // دالة حذف التصنيف
  void _deleteCategory(String name) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("تأكيد الحذف", 
          style: GoogleFonts.cairo(color: deleteRed, fontWeight: FontWeight.w700)),
        content: Text("هل أنت متأكد من حذف تصنيف ($name)؟\n\nملاحظة: سيتم نقل جميع المنتجات التابعة له إلى تصنيف (أخرى) تلقائياً للحفاظ عليها."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: deleteRed, 
              foregroundColor: Colors.white,
              animationDuration: const Duration(milliseconds: 300),
            ),
            onPressed: () async {
              await DatabaseHelper.instance.deleteCategory(name);
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadCategories();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم الحذف ونقل المنتجات بنجاح."), backgroundColor: successGreen),
              );
            },
            child: Text("حذف", style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("إدارة التصنيفات", 
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: gamingPurple,
        foregroundColor: Colors.white,
      ),
      body: _categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                
                // نمنع المستخدم من تعديل أو حذف تصنيف "أخرى" لأنه مهم للنظام
                bool isDefault = cat == 'أخرى';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: gamingPurple.withValues(alpha: 0.2),
                      child: const Icon(Icons.category, color: gamingPurple),
                    ),
                    title: Text(cat, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
                    trailing: isDefault 
                        ? Text("تصنيف افتراضي", 
                          style: GoogleFonts.cairo(color: Colors.grey, fontWeight: FontWeight.bold))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: editBlue),
                                tooltip: "تعديل",
                                onPressed: () => _showEditCategoryDialog(cat),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: deleteRed),
                                tooltip: "حذف",
                                onPressed: () => _deleteCategory(cat),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: gamingPurple,
        foregroundColor: Colors.white,
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add),
        label: Text("تصنيف جديد", 
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        splashColor: Colors.white.withOpacity(0.3),
      ),
    );
  }
}