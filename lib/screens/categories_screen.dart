import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  void _loadCategories() async {
    final cats = await DatabaseHelper.instance.getCategories();
    setState(() {
      _categories = cats;
    });
  }

  void _showAddCategoryDialog() {
    final TextEditingController controller = TextEditingController();
    const Color primaryBrown = Color(0xFF3E2723);
    const Color accentGold = Color(0xFFD4AF37);
    const Color categoryColor = Color(0xFF7B1FA2);
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
              colors: [surfaceBeige, surfaceBeige.withValues(alpha: 0.8)],
            ),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.category,
                  color: categoryColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "إضافة تصنيف جديد",
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: primaryBrown,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: "اسم التصنيف",
                  labelStyle: GoogleFonts.cairo(
                    color: primaryBrown.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(Icons.category, color: categoryColor),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentGold, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentGold, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentGold, width: 2.5),
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
                        backgroundColor: categoryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        String newCat = controller.text.trim();
                        if (newCat.isNotEmpty) {
                          int result =
                              await DatabaseHelper.instance.addCategory(newCat);
                          if (!context.mounted) return;
                          Navigator.pop(context);

                          if (result == -1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "هذا التصنيف موجود مسبقاً!",
                                  style: GoogleFonts.cairo(),
                                ),
                                backgroundColor:
                                    const Color(0xFFC62828),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            _loadCategories();
                          }
                        }
                      },
                      child: Text(
                        "حفظ",
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

  void _showEditCategoryDialog(String oldName) {
    final TextEditingController controller =
        TextEditingController(text: oldName);
    const Color primaryBrown = Color(0xFF3E2723);
    const Color accentGold = Color(0xFFD4AF37);
    const Color categoryColor = Color(0xFF1565C0);
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
              colors: [surfaceBeige, surfaceBeige.withValues(alpha: 0.8)],
            ),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit,
                  color: categoryColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "تعديل التصنيف",
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: primaryBrown,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: "الاسم الجديد",
                  labelStyle: GoogleFonts.cairo(
                    color: primaryBrown.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(Icons.edit, color: categoryColor),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentGold, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentGold, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentGold, width: 2.5),
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
                        backgroundColor: categoryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        String newName = controller.text.trim();
                        if (newName.isNotEmpty && newName != oldName) {
                          await DatabaseHelper.instance
                              .updateCategory(oldName, newName);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          _loadCategories();
                        }
                      },
                      child: Text(
                        "تحديث",
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

  void _deleteCategory(String name) async {
    const Color primaryBrown = Color(0xFF3E2723);
    const Color accentGold = Color(0xFFD4AF37);
    const Color errorColor = Color(0xFFC62828);
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
              colors: [surfaceBeige, surfaceBeige.withValues(alpha: 0.8)],
            ),
            border: Border.all(
              color: errorColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: errorColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "تأكيد الحذف",
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: primaryBrown,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "هل أنت متأكد من حذف تصنيف ($name)؟\n\nملاحظة: سيتم نقل جميع المنتجات التابعة له إلى تصنيف (أخرى) تلقائياً.",
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: primaryBrown.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
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
                        backgroundColor: errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await DatabaseHelper.instance.deleteCategory(name);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        _loadCategories();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "تم الحذف ونقل المنتجات بنجاح.",
                              style: GoogleFonts.cairo(),
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(
                        "حذف",
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

  @override
  Widget build(BuildContext context) {
    const Color primaryBrown = Color(0xFF3E2723);
    const Color categoryColor = Color(0xFF7B1FA2);
    const Color surfaceBeige = Color(0xFFF5E6D3);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "📂 إدارة التصنيفات",
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: categoryColor,
        elevation: 8,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [surfaceBeige, surfaceBeige.withValues(alpha: 0.7)],
          ),
        ),
        child: _categories.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category,
                      size: 80,
                      color: primaryBrown.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "لا توجد تصنيفات",
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: primaryBrown.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  bool isDefault = cat == 'أخرى';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
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
                          color: categoryColor.withValues(alpha: 0.3),
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
                                color:
                                    categoryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.category,
                                color: categoryColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                cat,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: primaryBrown,
                                ),
                              ),
                            ),
                            if (isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "افتراضي ⭐",
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: categoryColor,
                                  ),
                                ),
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () =>
                                        _showEditCategoryDialog(cat),
                                    child: Icon(
                                      Icons.edit,
                                      color: const Color(0xFF1565C0),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  InkWell(
                                    onTap: () => _deleteCategory(cat),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Color(0xFFC62828),
                                      size: 20,
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
        backgroundColor: categoryColor,
        elevation: 12,
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add_circle, size: 28),
        label: Text(
          "تصنيف جديد",
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}