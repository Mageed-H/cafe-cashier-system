import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_helper.dart';
import '../screens/table_details_screen.dart';

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

class _TableCardState extends State<TableCard> with SingleTickerProviderStateMixin {
  bool _isBusy = false;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _checkTableStatus();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _checkTableStatus() async {
    String type = widget.isGamingTable ? 'gaming' : 'cafeteria';
    bool busy =
        await DatabaseHelper.instance.isTableBusy(widget.tableNumber, type);

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
    const Color primaryBrown = Color(0xFF3E2723);
    const Color accentGold = Color(0xFFD4AF37);
    const Color cafColor = Color(0xFF6D4C41);
    const Color gamingColor = Color(0xFF7B1FA2);

    final cardColor = _isBusy
        ? const Color(0xFFD32F2F)
        : (widget.isGamingTable ? gamingColor : cafColor);

    final cardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        cardColor,
        cardColor.withOpacity(0.85),
      ],
    );

    return MouseRegion(
      onEnter: (_) {
        _scaleController.forward();
      },
      onExit: (_) {
        _scaleController.reverse();
      },
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.08).animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
        ),
        child: GestureDetector(
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
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: cardGradient,
              boxShadow: [
                BoxShadow(
                  color: cardColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Accent border
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accentGold.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                ),
                // Content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isGamingTable)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.sports_esports,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      if (widget.isGamingTable) const SizedBox(height: 8),
                      if (_isBusy)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "مشغولة",
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryBrown,
                            ),
                          ),
                        ),
                      SizedBox(height: _isBusy ? 4 : 0),
                      Text(
                        widget.isGamingTable
                            ? "ألعاب\n${widget.tableNumber}"
                            : "طاولة ${widget.tableNumber}",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
