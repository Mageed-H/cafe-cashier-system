import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';
import '../widgets/main_drawer.dart';
import '../widgets/table_card.dart'; // 👇 استدعاء ويدجت الكافتريا

import 'table_details_screen.dart';
import 'settings_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isListeningForSecret = false;
  final List<String> _secretBuffer = [];

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (HardwareKeyboard.instance.isControlPressed &&
          HardwareKeyboard.instance.isShiftPressed &&
          HardwareKeyboard.instance.isAltPressed) {
        _isListeningForSecret = true; 
        _secretBuffer.clear(); 
        return false;
      }

      if (_isListeningForSecret) {
        if (event.logicalKey.keyLabel.length == 1) {
          _secretBuffer.add(event.logicalKey.keyLabel.toLowerCase());
          String typed = _secretBuffer.join('');

          if ("devmh".startsWith(typed)) {
            if (typed == "devmh") {
              _isListeningForSecret = false;
              _secretBuffer.clear();
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())).then((_) => refreshScreen());
            }
          } else {
            _isListeningForSecret = false;
            _secretBuffer.clear();
          }
        }
      }
    }
    return false; 
  }

  void refreshScreen() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text("نظام كاشير الكفتريا", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange[400],
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.restaurant), text: " صالة الكافتريا"),
              Tab(icon: Icon(Icons.sports_esports), text: " صالة الألعاب"),
            ],
          ),
        ),
        
        drawer: MainDrawer(onRefresh: refreshScreen), 
        body: TabBarView(
          children: [
            // ================= التبويب الأول: صالة الكافتريا =================
            FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getTables(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("لا توجد طاولات حالياً."));
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => TableCard(tableNumber: snapshot.data![index]['table_number'], isGamingTable: false), 
                );
              },
            ),

            // ================= التبويب الثاني: صالة الألعاب =================
            FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getGamingTables(), 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("يرجى إضافة طاولات ألعاب من الإعدادات."));
                return GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.0),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => TableCard(tableNumber: snapshot.data![index]['table_number'], isGamingTable: true),
                );
              },
            ),
          ],
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.green[600],
          elevation: 10,
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const TableDetailsScreen(tableNumber: 0)));
            refreshScreen(); 
          },
          icon: const Icon(Icons.takeout_dining, size: 28, color: Colors.white),
          label: const Text("طلب سَفَري جديد (Takeaway)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}