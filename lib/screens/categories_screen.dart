import 'package:flutter/material.dart';
import '../services/database_helper.dart';

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
        title: const Text("إضافة تصنيف جديد", style: TextStyle(color: Colors.purple)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "اسم التصنيف",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category, color: Colors.purple),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              String newCat = controller.text.trim();
              if (newCat.isNotEmpty) {
                int result = await DatabaseHelper.instance.addCategory(newCat);
                if (!context.mounted) return;
                Navigator.pop(context);
                
                if (result == -1) {
                  // معناها التصنيف موجود مسبقاً (Unique Constraint)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("هذا التصنيف موجود مسبقاً!"), backgroundColor: Colors.red),
                  );
                } else {
                  _loadCategories(); // تحديث الشاشة
                }
              }
            },
            child: const Text("حفظ"),
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
        title: const Text("تعديل التصنيف", style: TextStyle(color: Colors.blue)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "الاسم الجديد",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit, color: Colors.blue),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () async {
              String newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                await DatabaseHelper.instance.updateCategory(oldName, newName);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadCategories();
              }
            },
            child: const Text("تحديث"),
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
        title: const Text("تأكيد الحذف", style: TextStyle(color: Colors.red)),
        content: Text("هل أنت متأكد من حذف تصنيف ($name)؟\n\nملاحظة: سيتم نقل جميع المنتجات التابعة له إلى تصنيف (أخرى) تلقائياً للحفاظ عليها."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await DatabaseHelper.instance.deleteCategory(name);
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadCategories();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم الحذف ونقل المنتجات بنجاح."), backgroundColor: Colors.green),
              );
            },
            child: const Text("حذف"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة التصنيفات", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple[400], // لون مميز للتصنيفات
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
                      backgroundColor: Colors.purple[100],
                      child: const Icon(Icons.category, color: Colors.purple),
                    ),
                    title: Text(cat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    trailing: isDefault 
                        ? const Text("تصنيف افتراضي", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                tooltip: "تعديل",
                                onPressed: () => _showEditCategoryDialog(cat),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
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
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add),
        label: const Text("تصنيف جديد", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}