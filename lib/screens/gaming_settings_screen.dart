import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class GamingSettingsScreen extends StatefulWidget {
  const GamingSettingsScreen({super.key});

  @override
  State<GamingSettingsScreen> createState() => _GamingSettingsScreenState();
}

class _GamingSettingsScreenState extends State<GamingSettingsScreen> {
  final TextEditingController _tableController = TextEditingController();
  
  // متغيرات الأسعار للأنواع الـ 3 (فردي وزوجي)
  final TextEditingController _ps4Single = TextEditingController();
  final TextEditingController _ps4Multi = TextEditingController();
  final TextEditingController _ps5Single = TextEditingController();
  final TextEditingController _ps5Multi = TextEditingController();
  final TextEditingController _billSingle = TextEditingController();
  final TextEditingController _billMulti = TextEditingController();
  
  List<Map<String, dynamic>> _tables = [];

  @override
  void initState() {
    super.initState();
    _loadPrices();
    _loadTables();
  }

  void _loadPrices() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ps4Single.text = (prefs.getDouble('ps4_single') ?? 2000).toString();
      _ps4Multi.text = (prefs.getDouble('ps4_multi') ?? 3000).toString();
      _ps5Single.text = (prefs.getDouble('ps5_single') ?? 3000).toString();
      _ps5Multi.text = (prefs.getDouble('ps5_multi') ?? 4000).toString();
      _billSingle.text = (prefs.getDouble('bill_single') ?? 4000).toString();
      _billMulti.text = (prefs.getDouble('bill_multi') ?? 5000).toString();
    });
  }

  void _savePrices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ps4_single', double.tryParse(_ps4Single.text) ?? 2000);
    await prefs.setDouble('ps4_multi', double.tryParse(_ps4Multi.text) ?? 3000);
    await prefs.setDouble('ps5_single', double.tryParse(_ps5Single.text) ?? 3000);
    await prefs.setDouble('ps5_multi', double.tryParse(_ps5Multi.text) ?? 4000);
    await prefs.setDouble('bill_single', double.tryParse(_billSingle.text) ?? 4000);
    await prefs.setDouble('bill_multi', double.tryParse(_billMulti.text) ?? 5000);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حفظ جميع الأسعار!"), backgroundColor: Colors.green));
  }

  void _loadTables() async {
    final data = await DatabaseHelper.instance.getGamingTables();
    setState(() { _tables = data; });
  }

  void _addTable() async {
    if (_tableController.text.isNotEmpty) {
      await DatabaseHelper.instance.addGamingTable(int.parse(_tableController.text));
      _tableController.clear();
      _loadTables();
      FocusScope.of(context).unfocus(); 
    }
  }

  void _deleteTable(int number) async {
    await DatabaseHelper.instance.deleteGamingTable(number);
    _loadTables();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إعدادات صالة الألعاب"), backgroundColor: Colors.purple[400], foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(15.0),
        children: [
          // إعدادات الأسعار الثابتة
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  const Text("قائمة أسعار الساعة (بالدينار):", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
                  const SizedBox(height: 10),
                  Row(children: [Expanded(child: TextField(controller: _ps4Single, decoration: const InputDecoration(labelText: "PS4 فردي", border: OutlineInputBorder()))), const SizedBox(width: 5), Expanded(child: TextField(controller: _ps4Multi, decoration: const InputDecoration(labelText: "PS4 زوجي", border: OutlineInputBorder())))]),
                  const SizedBox(height: 10),
                  Row(children: [Expanded(child: TextField(controller: _ps5Single, decoration: const InputDecoration(labelText: "PS5 فردي", border: OutlineInputBorder()))), const SizedBox(width: 5), Expanded(child: TextField(controller: _ps5Multi, decoration: const InputDecoration(labelText: "PS5 زوجي", border: OutlineInputBorder())))]),
                  const SizedBox(height: 10),
                  Row(children: [Expanded(child: TextField(controller: _billSingle, decoration: const InputDecoration(labelText: "بليارد فردي", border: OutlineInputBorder()))), const SizedBox(width: 5), Expanded(child: TextField(controller: _billMulti, decoration: const InputDecoration(labelText: "بليارد زوجي", border: OutlineInputBorder())))]),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white), onPressed: _savePrices, icon: const Icon(Icons.save), label: const Text("حفظ الأسعار"))
                ],
              ),
            ),
          ),
          
          const Divider(thickness: 2, height: 30),
          
          // إدارة طاولات الألعاب
          const Text("طاولات قسم الألعاب:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: _tableController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "رقم طاولة الألعاب", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              SizedBox(height: 55, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: _addTable, icon: const Icon(Icons.add), label: const Text("إضافة"))),
            ],
          ),
          const SizedBox(height: 15),
          
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5),
            itemCount: _tables.length,
            itemBuilder: (context, index) {
              int tNum = _tables[index]['table_number'];
              return Card(
                color: Colors.purple[50],
                child: Stack(
                  children: [
                    Center(child: Text("طاولة ألعاب\n$tNum", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                    Positioned(top: 0, right: 0, child: IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteTable(tNum))),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}