import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isListeningForSecret = false;
  final List<String> _secretBuffer = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _tabController.dispose();
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
    const Color primaryBrown = Color(0xFF3E2723);
    const Color accentGold = Color(0xFFD4AF37);
    const Color surfaceBeige = Color(0xFFF5E6D3);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "☕ لمة كافيه - نظام الكاشير",
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryBrown,
        centerTitle: true,
        elevation: 8,
        shadowColor: primaryBrown.withOpacity(0.5),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: TabBar(
            controller: _tabController,
            labelColor: accentGold,
            unselectedLabelColor: Colors.white60,
            indicatorColor: accentGold,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: accentGold, width: 3),
              ),
            ),
            labelStyle: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                icon: const Icon(Icons.restaurant_menu, size: 24),
                text: " صالة الكافتريا",
              ),
              Tab(
                icon: const Icon(Icons.sports_esports, size: 24),
                text: " صالة الألعاب",
              ),
            ],
          ),
        ),
      ),
      
      drawer: MainDrawer(onRefresh: refreshScreen),
      
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              surfaceBeige,
              surfaceBeige.withOpacity(0.7),
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            // ================= التبويب الأول: صالة الكافتريا =================
            FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getTables(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "لا توجد طاولات حالياً.",
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: primaryBrown,
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => TableCard(
                    tableNumber: snapshot.data![index]['table_number'],
                    isGamingTable: false,
                  ),
                );
              },
            ),

            // ================= التبويب الثاني: صالة الألعاب =================
            FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getGamingTables(), 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "يرجى إضافة طاولات ألعاب من الإعدادات.",
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: primaryBrown,
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => TableCard(
                    tableNumber: snapshot.data![index]['table_number'],
                    isGamingTable: true,
                  ),
                );
              },
            ),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF558B2F),
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TableDetailsScreen(tableNumber: 0),
              ),
            );
            refreshScreen(); 
          },
          icon: const Icon(Icons.takeout_dining, size: 28, color: Colors.white),
          label: Text(
            "طلب سَفَري جديد (Takeaway)",
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}