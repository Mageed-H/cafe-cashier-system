import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../screens/table_details_screen.dart';

// 🎨 Brand Colors
const Color primaryBrown = Color(0xFF3E2723);
const Color accentGold = Color(0xFFD4AF37);
const Color gamingPurple = Color(0xFF7B1FA2);
const Color cafeteriaBrown = Color(0xFF6D4C41);
const Color busyRed = Color(0xFFD32F2F);
const Color successGreen = Color(0xFF2E7D32);

class TableCard extends StatefulWidget {
  final int tableNumber;
  final bool isGamingTable;

  const TableCard({
    required this.tableNumber,
    this.isGamingTable = false,
    super.key,
  });

  @override
  State<TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<TableCard> {
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _checkTableStatus();
  }

  // هذه الدالة هي اللي كانت تسبب التضارب بالألوان
  void _checkTableStatus() async {
    // نحدد النوع بناءً على المتغير الموجود في الـ widget
    String type = widget.isGamingTable ? 'gaming' : 'cafeteria';

    // 1. نفحص هل اكو طلبات (أكل أو لعب) غير مدفوعة لهذا النوع تحديداً؟
    // الآن نمرر الوسيط الثاني (type) اللي أضفناه في الـ DatabaseHelper
    bool busy =
        await DatabaseHelper.instance.isTableBusy(widget.tableNumber, type);

    // 2. إذا كانت طاولة ألعاب، نفحص أيضاً حالة العدادات (Timer)
    if (!busy && widget.isGamingTable) {
      final timers =
          await DatabaseHelper.instance.getTimersForTable(widget.tableNumber);
      busy = timers.any((t) => t['is_playing'] == 1);
    }

    if (mounted) {
      setState(() {
        _isBusy = busy;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TableDetailsScreen(
              tableNumber: widget.tableNumber,
              isGamingTable: widget.isGamingTable,
            ),
          ),
        );
        _checkTableStatus();
      },
      child: Card(
        // التلوين صار الآن يعتمد على حالة دقيقة ومنفصلة لكل صالة
        color: _isBusy
            ? busyRed
            : (widget.isGamingTable ? gamingPurple : cafeteriaBrown),
        elevation: _isBusy ? 8 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isGamingTable)
                const Icon(Icons.sports_esports, color: Colors.white, size: 30),
              if (widget.isGamingTable) const SizedBox(height: 5),
              Text(
                widget.isGamingTable
                    ? "طاولة ألعاب\n${widget.tableNumber}"
                    : "طاولة ${widget.tableNumber}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
