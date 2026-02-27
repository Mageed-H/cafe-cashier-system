import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_helper.dart';

// 🎨 Brand Colors
const Color primaryBrown = Color(0xFF3E2723);
const Color accentGold = Color(0xFFD4AF37);
const Color surfaceBeige = Color(0xFFF5E6D3);
const Color busyRed = Color(0xFFD32F2F);
const Color successGreen = Color(0xFF2E7D32);
const Color editBlue = Color(0xFF1565C0);

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  List<String> _categories = ['أخرى']; 

  @override
  void initState() {
    super.initState();
    _loadData(); 
  }

  void _loadData() async {
    final cats = await DatabaseHelper.instance.getCategories();
    final prods = await DatabaseHelper.instance.getProducts();
    setState(() {
      if (cats.isNotEmpty) _categories = cats;
      _products = prods;
    });
  }

  void _showAddProductDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    String selectedCategory = _categories.first; 
    String? selectedImagePath; // 👇 متغير لحفظ مسار الصورة

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("إضافة منتج جديد", 
              style: GoogleFonts.cairo(color: successGreen, fontWeight: FontWeight.w700)),
            content: SingleChildScrollView( // ضفناها حتى الشاشة ما تضيق
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 👇 عرض الصورة المختارة أو أيقونة افتراضية 👇
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10), border: Border.all(color: accentGold)),
                    child: selectedImagePath != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(selectedImagePath!), fit: BoxFit.cover))
                        : const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGold, 
                      foregroundColor: Colors.black87,
                      animationDuration: const Duration(milliseconds: 300),
                    ),
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                      if (result != null) {
                        setDialogState(() { selectedImagePath = result.files.single.path; });
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: Text("اختيار صورة", style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                  ),
                  const Divider(),
                  
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "اسم المنتج")),
                  TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "السعر (دينار)")),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory, 
                    decoration: const InputDecoration(labelText: "التصنيف", border: OutlineInputBorder()),
                    items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (val) { setDialogState(() { selectedCategory = val!; }); },
                  ),
                ],
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
                  if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                    await DatabaseHelper.instance.addProduct({
                      'name': nameController.text, 
                      'price': double.parse(priceController.text), 
                      'category': selectedCategory,
                      'image_path': selectedImagePath // حفظ الصورة بالداتابيس
                    });
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadData(); 
                  }
                },
                child: Text("حفظ", style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    final TextEditingController nameController = TextEditingController(text: product['name']);
    final TextEditingController priceController = TextEditingController(text: product['price'].toString());
    String selectedCategory = product['category'] != null && _categories.contains(product['category']) ? product['category'] : _categories.first;
    String? selectedImagePath = product['image_path']; // جلب مسار الصورة القديم

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("تعديل المنتج", 
              style: GoogleFonts.cairo(color: editBlue, fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10), border: Border.all(color: editBlue)),
                    child: selectedImagePath != null && File(selectedImagePath!).existsSync()
                        ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(selectedImagePath!), fit: BoxFit.cover))
                        : const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: editBlue, 
                      foregroundColor: Colors.white,
                      animationDuration: const Duration(milliseconds: 300),
                    ),
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                      if (result != null) {
                        setDialogState(() { selectedImagePath = result.files.single.path; });
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: Text("تغيير الصورة", style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                  ),
                  const Divider(),

                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "اسم المنتج الجديد")),
                  TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "السعر الجديد (دينار)")),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory, 
                    decoration: const InputDecoration(labelText: "التصنيف", border: OutlineInputBorder()),
                    items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (val) { setDialogState(() { selectedCategory = val!; }); },
                  ),
                ],
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
                  if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                    await DatabaseHelper.instance.updateProduct(
                      product['id'], 
                      nameController.text, 
                      double.parse(priceController.text), 
                      selectedCategory,
                      selectedImagePath // تحديث مسار الصورة
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadData(); 
                  }
                },
                child: Text("تحديث", style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("إدارة المنتجات", 
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: accentGold,
        foregroundColor: Colors.black,
      ),
      body: _products.isEmpty
          ? const Center(child: Text("لا توجد منتجات، اضغط على + للإضافة."))
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                String? imgPath = product['image_path'];
                bool hasImage = imgPath != null && File(imgPath).existsSync();

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    // 👇 عرض الصورة باللستة الدائرية 👇
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: accentGold.withValues(alpha: 0.3),
                      backgroundImage: hasImage ? FileImage(File(imgPath)) : null,
                      child: hasImage ? null : const Icon(Icons.fastfood, color: Colors.orange),
                    ),
                    title: Text(product['name'], 
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    subtitle: Text("${product['price']} دينار | ${product['category'] ?? 'بدون تصنيف'}", 
                      style: GoogleFonts.cairo(color: successGreen, fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: editBlue), onPressed: () => _showEditProductDialog(product)),
                        IconButton(icon: const Icon(Icons.delete, color: busyRed), onPressed: () => _deleteProduct(product['id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accentGold,
        foregroundColor: Colors.black87,
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add),
        label: Text("منتج جديد", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        splashColor: Colors.black.withValues(alpha: 0.2),
      ),
    );
  }
}