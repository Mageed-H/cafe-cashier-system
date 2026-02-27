import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_helper.dart';

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
            title: const Text("إضافة منتج جديد"),
            content: SingleChildScrollView( // ضفناها حتى الشاشة ما تضيق
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 👇 عرض الصورة المختارة أو أيقونة افتراضية 👇
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange)),
                    child: selectedImagePath != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(selectedImagePath!), fit: BoxFit.cover))
                        : const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                      if (result != null) {
                        setDialogState(() { selectedImagePath = result.files.single.path; });
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text("اختيار صورة"),
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
                child: const Text("حفظ"),
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
            title: const Text("تعديل المنتج"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue)),
                    child: selectedImagePath != null && File(selectedImagePath!).existsSync()
                        ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(selectedImagePath!), fit: BoxFit.cover))
                        : const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                      if (result != null) {
                        setDialogState(() { selectedImagePath = result.files.single.path; });
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("تغيير الصورة"),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
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
                child: const Text("تحديث"),
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
      appBar: AppBar(title: const Text("إدارة المنتجات"), backgroundColor: Colors.orange[300]),
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
                      backgroundColor: Colors.orange[100],
                      backgroundImage: hasImage ? FileImage(File(imgPath)) : null,
                      child: hasImage ? null : const Icon(Icons.fastfood, color: Colors.orange),
                    ),
                    title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${product['price']} دينار | ${product['category'] ?? 'بدون تصنيف'}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditProductDialog(product)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProduct(product['id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.orange, onPressed: _showAddProductDialog, child: const Icon(Icons.add)),
    );
  }
}