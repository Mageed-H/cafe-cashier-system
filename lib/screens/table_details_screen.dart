// ignore_for_file: unused_field

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // مهم لقراءة اللوكو

class TableDetailsScreen extends StatefulWidget {
  final int tableNumber;
  final bool isGamingTable;

  const TableDetailsScreen(
      {required this.tableNumber, this.isGamingTable = false, super.key});

  @override
  State<TableDetailsScreen> createState() => _TableDetailsScreenState();
}

class _TableDetailsScreenState extends State<TableDetailsScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _cart = [];
  List<Map<String, dynamic>> _timers = [];
  List<String> _dbCategories = ['الكل'];
  double _discount = 0.0;
  String _selectedCategory = 'الكل';
  String _cafeName = "لمة كافيه";

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnpaidCart();
    _loadSettings();
    if (widget.isGamingTable) _loadTimers();
  }

  void _loadTimers() async {
    final data =
        await DatabaseHelper.instance.getTimersForTable(widget.tableNumber);
    setState(() {
      _timers = data;
    });
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cafeName = prefs.getString('cafe_name') ?? "لمة كافيه";
    });
  }

  void _loadData() async {
    final cats = await DatabaseHelper.instance.getCategories();
    final prods = await DatabaseHelper.instance.getProducts();
    setState(() {
      _dbCategories = ['الكل', ...cats];
      _products = prods;
    });
  }

  void _loadUnpaidCart() async {
    String type = widget.isGamingTable ? 'gaming' : 'cafeteria';
    final savedCart =
        await DatabaseHelper.instance.getUnpaidCart(widget.tableNumber, type);
    setState(() {
      _cart = savedCart;
    });
  }

  void _autoSaveCart() {
    String type = widget.isGamingTable ? 'gaming' : 'cafeteria';
    DatabaseHelper.instance.saveUnpaidCart(widget.tableNumber, _cart, type);
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      int existingIndex = _cart.indexWhere((item) =>
          item['name'] == product['name'] && item['price'] == product['price']);
      if (existingIndex != -1) {
        _cart[existingIndex]['quantity'] += 1;
      } else {
        _cart.add({
          'id': product['id'] ?? DateTime.now().millisecondsSinceEpoch % 100000,
          'name': product['name'],
          'price': product['price'],
          'quantity': 1,
          'printed_quantity': 0 // 👇 التعديل الأول: العنصر الجديد بعده ممطبوع
        });
      }
      _discount = 0.0;
    });
    _autoSaveCart();
  }

  double get _subTotal =>
      _cart.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  double get _finalPrice =>
      (_subTotal - _discount) < 0 ? 0 : (_subTotal - _discount);

  void _confirmPayment() async {
    String type = widget.isGamingTable ? 'gaming' : 'cafeteria';
    await DatabaseHelper.instance.confirmPayment(widget.tableNumber, type);
    if (mounted) Navigator.pop(context);
  }

  void _showConfirmPaymentDialog() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text("تأكيد الدفع"),
                content: Text("استلام مبلغ ($_finalPrice) دينار؟"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("تراجع")),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmPayment();
                      },
                      child: const Text("تأكيد"))
                ]));
  }

  void _cancelOrder() async {
    String type = widget.isGamingTable ? 'gaming' : 'cafeteria';
    await DatabaseHelper.instance.clearTableOrders(widget.tableNumber, type);
    if (mounted) Navigator.pop(context);
  }

  void _showDiscountDialog() {
    TextEditingController priceController =
        TextEditingController(text: _finalPrice.toString());
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text("تعديل السعر"),
                content: TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("إلغاء")),
                  ElevatedButton(
                      onPressed: () {
                        if (priceController.text.isNotEmpty) {
                          setState(() {
                            _discount =
                                _subTotal - double.parse(priceController.text);
                            if (_discount < 0) _discount = 0;
                          });
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text("تطبيق"))
                ]));
  }

  // ================= 👇 التعديل الثاني: دالة طباعة الشيف 👇 =================
  Future<void> _printChefReceipt() async {
    List<Map<String, dynamic>> newItems = [];
    List<Map<String, dynamic>> oldItems = [];

    // فرز الطلبات واستثناء اللعب
    for (var item in _cart) {
      if (item['name'].toString().startsWith('لعب')) continue;

      int qty = item['quantity'];
      int printedQty = item['printed_quantity'] ?? 0;

      if (qty > printedQty) {
        newItems.add({'name': item['name'], 'qty': qty - printedQty});
      }
      if (printedQty > 0) {
        oldItems.add({'name': item['name'], 'qty': printedQty});
      }
    }

    if (newItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('لا توجد طلبات جديدة لطباعتها للشيف!'),
          backgroundColor: Colors.orange));
      return;
    }

    // 1. تحميل الخطوط
    final fontTable = await PdfGoogleFonts.notoSansArabicRegular();
    final fontTableBold = await PdfGoogleFonts.notoSansArabicBold();

    // 2. تحميل خط إنجليزي كـ Fallback (احتياطي) للأحرف والرموز الأجنبية
    final fallbackFont = await PdfGoogleFonts.notoSansRegular();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                    child: pw.Text("وصل طلبات - المطبخ",
                        style: pw.TextStyle(
                            font: fontTableBold,
                            fontFallback: [fallbackFont],
                            fontSize: 16))),
                pw.Center(
                    child: pw.Text(
                        widget.isGamingTable
                            ? "طاولة ألعاب: ${widget.tableNumber}"
                            : (widget.tableNumber == 0
                                ? "طلب سَفَري"
                                : "طاولة رقم: ${widget.tableNumber}"),
                        style: pw.TextStyle(
                            font: fontTableBold,
                            fontFallback: [fallbackFont],
                            fontSize: 14))),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1.5),
                pw.Text("الطلبات الجديدة",
                    style: pw.TextStyle(
                        font: fontTableBold,
                        fontFallback: [fallbackFont],
                        fontSize: 14)),
                pw.SizedBox(height: 5),
                ...newItems.map((item) => pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("- ${item['name']}",
                              style: pw.TextStyle(
                                  font: fontTableBold,
                                  fontFallback: [fallbackFont],
                                  fontSize: 14)),
                          pw.Text("x${item['qty']}",
                              style: pw.TextStyle(
                                  font: fontTableBold,
                                  fontFallback: [fallbackFont],
                                  fontSize: 16)),
                        ])),
                // if (oldItems.isNotEmpty) ...[
                //   pw.SizedBox(height: 15),
                //   pw.Divider(borderStyle: pw.BorderStyle.dashed),
                //   pw.Text(" طلبات سابقة ",
                //       style: pw.TextStyle(
                //           font: fontTable,
                //           fontFallback: [fallbackFont],
                //           fontSize: 10,
                //           color: PdfColors.grey700)),
                //   ...oldItems.map((item) => pw.Row(
                //           mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                //           children: [
                //             pw.Text(item['name'],
                //                 style: pw.TextStyle(
                //                     font: fontTable,
                //                     fontFallback: [fallbackFont],
                //                     fontSize: 10,
                //                     color: PdfColors.grey700)),
                //             pw.Text("x${item['qty']}",
                //                 style: pw.TextStyle(
                //                     font: fontTable,
                //                     fontFallback: [fallbackFont],
                //                     fontSize: 10,
                //                     color: PdfColors.grey700)),
                //           ])),
                // ]
              ],
            ),
          );
        },
      ),
    );

    // ==========================================
    // 👇 التعديل هنا: فحص وطباعة مباشرة أو نافذة 👇
    // ==========================================
    final prefs = await SharedPreferences.getInstance();
    final chefPrinterUrl =
        prefs.getString('chef_printer_url'); // جلب مسار طابعة المطبخ المحفوظ
    Printer? targetPrinter;

    if (chefPrinterUrl != null) {
      final printers = await Printing.listPrinters();
      try {
        targetPrinter = printers.firstWhere((p) => p.url == chefPrinterUrl);
      } catch (e) {
        // الطابعة مفصولة أو ممسوحة من النظام
      }
    }

    if (targetPrinter != null) {
      // 1️⃣ طباعة مباشرة بالخلفية بدون ما تطلع أي نافذة للكاشير
      await Printing.directPrintPdf(
        printer: targetPrinter,
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Chef_Receipt_${widget.tableNumber}',
      );
    } else {
      // 2️⃣ إذا الكاشير بعده ما محدد طابعة للمطبخ، نفتحله النافذة العادية
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Chef_Receipt_${widget.tableNumber}',
      );
    }
    // ==========================================

    setState(() {
      for (var item in _cart) {
        if (!item['name'].toString().startsWith('لعب')) {
          item['printed_quantity'] = item['quantity'];
        }
      }
    });
    _autoSaveCart();
  }
  // =========================================================================

  Future<void> _printActualReceipt() async {
    final fontTable = await PdfGoogleFonts.notoSansArabicRegular();
    final fontTableBold = await PdfGoogleFonts.notoSansArabicBold();
    final fontDecorative = await PdfGoogleFonts.amiriBold();

    // الخط الاحتياطي للأحرف الإنجليزية والأرقام والرموز
    final fallbackFont = await PdfGoogleFonts.notoSansRegular();

    // ==========================================
    // 👇 1. جلب أرقام الهواتف الذكي 👇
    // ==========================================
    final prefs = await SharedPreferences.getInstance();
    String savedPhones = prefs.getString('cafe_phones') ?? "";

    // فصل الأرقام وتجاهل الأرقام الوهمية اللي بيها x
    List<String> phoneList = savedPhones
        .split(RegExp(r'[-/،,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !e.toLowerCase().contains('x'))
        .toList();

    // ==========================================
    // 👇 2. محاولة تحميل الشعار (اللوكو) 👇
    // ==========================================
    pw.MemoryImage? logoImage;
    try {
      final ByteData bytes = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      // إذا ما لقى اللوكو يكمل طبيعي
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // 👇 طباعة اللوكو بالوسط إذا تم تحميله بنجاح 👇
                if (logoImage != null) ...[
                  pw.Image(logoImage,
                      width: 65, height: 65), // تكدر تغير الحجم من هنا
                  pw.SizedBox(height: 5),
                ],

                pw.Text(_cafeName,
                    style: pw.TextStyle(
                        font: fontDecorative,
                        fontFallback: [fallbackFont],
                        fontSize: 24)),
                pw.Text("فاتورة طلب",
                    style: pw.TextStyle(
                        font: fontTable,
                        fontFallback: [fallbackFont],
                        fontSize: 11)),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        widget.isGamingTable
                            ? "طاولة ألعاب: ${widget.tableNumber}"
                            : (widget.tableNumber == 0
                                ? "طلب سَفَري"
                                : "طاولة رقم: ${widget.tableNumber}"),
                        style: pw.TextStyle(
                            font: fontTableBold,
                            fontFallback: [fallbackFont],
                            fontSize: 11)),
                    pw.Text(DateTime.now().toString().substring(0, 16),
                        style: pw.TextStyle(
                            font: fontTable,
                            fontFallback: [fallbackFont],
                            fontSize: 11)),
                  ],
                ),
                pw.Divider(thickness: 1.5),

                // ==========================================
                // 👇 3. رجعنا الـ Row و Expanded القديم للطلبات 👇
                // ==========================================
                pw.Container(
                  decoration: const pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              width: 1.2, color: PdfColors.black))),
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                          flex: 3,
                          child: pw.Text("اسم المادة",
                              style: pw.TextStyle(
                                  font: fontTableBold,
                                  fontFallback: [fallbackFont],
                                  fontSize: 10),
                              textAlign: pw.TextAlign.right)),
                      pw.Expanded(
                          flex: 1,
                          child: pw.Text("العدد",
                              style: pw.TextStyle(
                                  font: fontTableBold,
                                  fontFallback: [fallbackFont],
                                  fontSize: 10),
                              textAlign: pw.TextAlign.center)),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text("السعر",
                              style: pw.TextStyle(
                                  font: fontTableBold,
                                  fontFallback: [fallbackFont],
                                  fontSize: 10),
                              textAlign: pw.TextAlign.center)),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text("الإجمالي",
                              style: pw.TextStyle(
                                  font: fontTableBold,
                                  fontFallback: [fallbackFont],
                                  fontSize: 10),
                              textAlign: pw.TextAlign.left)),
                    ],
                  ),
                ),
                ..._cart.map((item) {
                  return pw.Container(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(
                            bottom: pw.BorderSide(
                                width: 0.5, color: PdfColors.grey400))),
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                            flex: 3,
                            child: pw.Text(item['name'],
                                style: pw.TextStyle(
                                    font: fontTable,
                                    fontFallback: [fallbackFont],
                                    fontSize: 10),
                                textAlign: pw.TextAlign.right)),
                        pw.Expanded(
                            flex: 1,
                            child: pw.Text("${item['quantity']}",
                                style: pw.TextStyle(
                                    font: fontTable,
                                    fontFallback: [fallbackFont],
                                    fontSize: 10),
                                textAlign: pw.TextAlign.center)),
                        pw.Expanded(
                            flex: 2,
                            child: pw.Text("${item['price']}",
                                style: pw.TextStyle(
                                    font: fontTable,
                                    fontFallback: [fallbackFont],
                                    fontSize: 10),
                                textAlign: pw.TextAlign.center)),
                        pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                                "${item['price'] * item['quantity']}",
                                style: pw.TextStyle(
                                    font: fontTable,
                                    fontFallback: [fallbackFont],
                                    fontSize: 10),
                                textAlign: pw.TextAlign.left)),
                      ],
                    ),
                  );
                }),
                // ==========================================

                pw.SizedBox(height: 10),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("المجموع:",
                          style: pw.TextStyle(
                              font: fontTableBold,
                              fontFallback: [fallbackFont],
                              fontSize: 12)),
                      pw.Text("$_subTotal دينار",
                          style: pw.TextStyle(
                              font: fontTableBold,
                              fontFallback: [fallbackFont],
                              fontSize: 12))
                    ]),
                if (_discount > 0)
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("الخصم:",
                            style: pw.TextStyle(
                                font: fontTable,
                                fontFallback: [fallbackFont],
                                fontSize: 12,
                                color: PdfColors.red800)),
                        pw.Text("$_discount دينار -",
                            style: pw.TextStyle(
                                font: fontTable,
                                fontFallback: [fallbackFont],
                                fontSize: 12,
                                color: PdfColors.red800))
                      ]),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("الإجمالي:",
                          style: pw.TextStyle(
                              font: fontTableBold,
                              fontFallback: [fallbackFont],
                              fontSize: 16)),
                      pw.Text("$_finalPrice دينار",
                          style: pw.TextStyle(
                              font: fontTableBold,
                              fontFallback: [fallbackFont],
                              fontSize: 16))
                    ]),

                // ==========================================
                // 👇 4. الأرقام بداخل Table فقط والعبارة المطلوبة 👇
                // ==========================================
                pw.SizedBox(height: 15),
                pw.Divider(borderStyle: pw.BorderStyle.dotted),

                if (phoneList.isNotEmpty) ...[
                  pw.Table(children: [
                    pw.TableRow(children: [
                      pw.Text("رقم الهاتف: ${phoneList[0]}",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              font: fontTableBold,
                              fontFallback: [fallbackFont],
                              fontSize: 10)),
                    ]),
                    if (phoneList.length > 1)
                      ...phoneList
                          .sublist(1)
                          .map((phone) => pw.TableRow(children: [
                                pw.Text(phone,
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(
                                        font: fontTableBold,
                                        fontFallback: [fallbackFont],
                                        fontSize: 10)),
                              ])),
                  ]),
                  pw.SizedBox(height: 8),
                ],

                pw.Text("هنا تبدي اللمة",
                    style: pw.TextStyle(
                        font: fontDecorative,
                        fontFallback: [fallbackFont],
                        fontSize: 14)),
                pw.Text("وهنا يبقى الأثر",
                    style: pw.TextStyle(
                        font: fontDecorative,
                        fontFallback: [fallbackFont],
                        fontSize: 14)),

                pw.SizedBox(height: 6),

                pw.Text("شكراً لزيارتكم!",
                    style: pw.TextStyle(
                        font: fontTable,
                        fontFallback: [fallbackFont],
                        fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );

    // ==========================================
    // فحص وطباعة مباشرة أو نافذة للكاشير
    // ==========================================
    final cashierPrinterUrl = prefs.getString('cashier_printer_url');
    Printer? targetPrinter;

    if (cashierPrinterUrl != null) {
      final printers = await Printing.listPrinters();
      try {
        targetPrinter = printers.firstWhere((p) => p.url == cashierPrinterUrl);
      } catch (e) {}
    }

    if (targetPrinter != null) {
      await Printing.directPrintPdf(
        printer: targetPrinter,
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Receipt_${widget.tableNumber}',
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Receipt_${widget.tableNumber}',
      );
    }
  }

  // Future<void> _printActualReceipt() async {
  //   final fontTable = await PdfGoogleFonts.notoSansArabicRegular();
  //   final fontTableBold = await PdfGoogleFonts.notoSansArabicBold();
  //   final fontDecorative = await PdfGoogleFonts.amiriBold();

  //   // 👇 الخط الاحتياطي للأحرف الإنجليزية والأرقام والرموز 👇
  //   final fallbackFont = await PdfGoogleFonts.notoSansRegular();

  //   final pdf = pw.Document();

  //   pdf.addPage(
  //     pw.Page(
  //       pageFormat: PdfPageFormat.roll80,
  //       margin: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
  //       build: (pw.Context context) {
  //         return pw.Directionality(
  //           textDirection: pw.TextDirection.rtl,
  //           child: pw.Column(
  //             crossAxisAlignment: pw.CrossAxisAlignment.center,
  //             children: [
  //               pw.Text(_cafeName,
  //                   style: pw.TextStyle(
  //                       font: fontDecorative,
  //                       fontFallback: [fallbackFont],
  //                       fontSize: 24)),
  //               pw.Text("فاتورة طلب",
  //                   style: pw.TextStyle(
  //                       font: fontTable,
  //                       fontFallback: [fallbackFont],
  //                       fontSize: 11)),
  //               pw.SizedBox(height: 10),
  //               pw.Row(
  //                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   pw.Text(
  //                       widget.isGamingTable
  //                           ? "طاولة ألعاب: ${widget.tableNumber}"
  //                           : (widget.tableNumber == 0
  //                               ? "طلب سَفَري"
  //                               : "طاولة رقم: ${widget.tableNumber}"),
  //                       style: pw.TextStyle(
  //                           font: fontTableBold,
  //                           fontFallback: [fallbackFont],
  //                           fontSize: 11)),
  //                   pw.Text(DateTime.now().toString().substring(0, 16),
  //                       style: pw.TextStyle(
  //                           font: fontTable,
  //                           fontFallback: [fallbackFont],
  //                           fontSize: 11)),
  //                 ],
  //               ),
  //               pw.Divider(thickness: 1.5),
  //               pw.Container(
  //                 decoration: const pw.BoxDecoration(
  //                     border: pw.Border(
  //                         bottom: pw.BorderSide(
  //                             width: 1.2, color: PdfColors.black))),
  //                 padding: const pw.EdgeInsets.only(bottom: 5),
  //                 child: pw.Row(
  //                   children: [
  //                     pw.Expanded(
  //                         flex: 3,
  //                         child: pw.Text("اسم المادة",
  //                             style: pw.TextStyle(
  //                                 font: fontTableBold,
  //                                 fontFallback: [fallbackFont],
  //                                 fontSize: 10),
  //                             textAlign: pw.TextAlign.right)),
  //                     pw.Expanded(
  //                         flex: 1,
  //                         child: pw.Text("العدد",
  //                             style: pw.TextStyle(
  //                                 font: fontTableBold,
  //                                 fontFallback: [fallbackFont],
  //                                 fontSize: 10),
  //                             textAlign: pw.TextAlign.center)),
  //                     pw.Expanded(
  //                         flex: 2,
  //                         child: pw.Text("السعر",
  //                             style: pw.TextStyle(
  //                                 font: fontTableBold,
  //                                 fontFallback: [fallbackFont],
  //                                 fontSize: 10),
  //                             textAlign: pw.TextAlign.center)),
  //                     pw.Expanded(
  //                         flex: 2,
  //                         child: pw.Text("الإجمالي",
  //                             style: pw.TextStyle(
  //                                 font: fontTableBold,
  //                                 fontFallback: [fallbackFont],
  //                                 fontSize: 10),
  //                             textAlign: pw.TextAlign.left)),
  //                   ],
  //                 ),
  //               ),
  //               ..._cart.map((item) {
  //                 return pw.Container(
  //                   decoration: const pw.BoxDecoration(
  //                       border: pw.Border(
  //                           bottom: pw.BorderSide(
  //                               width: 0.5, color: PdfColors.grey400))),
  //                   padding: const pw.EdgeInsets.symmetric(vertical: 4),
  //                   child: pw.Row(
  //                     children: [
  //                       pw.Expanded(
  //                           flex: 3,
  //                           child: pw.Text(item['name'],
  //                               style: pw.TextStyle(
  //                                   font: fontTable,
  //                                   fontFallback: [fallbackFont],
  //                                   fontSize: 10),
  //                               textAlign: pw.TextAlign.right)),
  //                       pw.Expanded(
  //                           flex: 1,
  //                           child: pw.Text("${item['quantity']}",
  //                               style: pw.TextStyle(
  //                                   font: fontTable,
  //                                   fontFallback: [fallbackFont],
  //                                   fontSize: 10),
  //                               textAlign: pw.TextAlign.center)),
  //                       pw.Expanded(
  //                           flex: 2,
  //                           child: pw.Text("${item['price']}",
  //                               style: pw.TextStyle(
  //                                   font: fontTable,
  //                                   fontFallback: [fallbackFont],
  //                                   fontSize: 10),
  //                               textAlign: pw.TextAlign.center)),
  //                       pw.Expanded(
  //                           flex: 2,
  //                           child: pw.Text(
  //                               "${item['price'] * item['quantity']}",
  //                               style: pw.TextStyle(
  //                                   font: fontTable,
  //                                   fontFallback: [fallbackFont],
  //                                   fontSize: 10),
  //                               textAlign: pw.TextAlign.left)),
  //                     ],
  //                   ),
  //                 );
  //               }),
  //               pw.SizedBox(height: 10),
  //               pw.Row(
  //                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     pw.Text("المجموع:",
  //                         style: pw.TextStyle(
  //                             font: fontTableBold,
  //                             fontFallback: [fallbackFont],
  //                             fontSize: 12)),
  //                     pw.Text("$_subTotal دينار",
  //                         style: pw.TextStyle(
  //                             font: fontTableBold,
  //                             fontFallback: [fallbackFont],
  //                             fontSize: 12))
  //                   ]),
  //               if (_discount > 0)
  //                 pw.Row(
  //                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       pw.Text("الخصم:",
  //                           style: pw.TextStyle(
  //                               font: fontTable,
  //                               fontFallback: [fallbackFont],
  //                               fontSize: 12,
  //                               color: PdfColors.red800)),
  //                       pw.Text("$_discount دينار -",
  //                           style: pw.TextStyle(
  //                               font: fontTable,
  //                               fontFallback: [fallbackFont],
  //                               fontSize: 12,
  //                               color: PdfColors.red800))
  //                     ]),
  //               pw.Divider(borderStyle: pw.BorderStyle.dashed),
  //               pw.Row(
  //                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     pw.Text("الإجمالي:",
  //                         style: pw.TextStyle(
  //                             font: fontTableBold,
  //                             fontFallback: [fallbackFont],
  //                             fontSize: 16)),
  //                     pw.Text("$_finalPrice دينار",
  //                         style: pw.TextStyle(
  //                             font: fontTableBold,
  //                             fontFallback: [fallbackFont],
  //                             fontSize: 16))
  //                   ]),
  //             ],
  //           ),
  //         );
  //       },
  //     ),
  //   );

  //   // ==========================================
  //   // 👇 فحص وطباعة مباشرة أو نافذة للكاشير 👇
  //   // ==========================================
  //   final prefs = await SharedPreferences.getInstance();
  //   final cashierPrinterUrl = prefs
  //       .getString('cashier_printer_url'); // جلب مسار طابعة الكاشير المحفوظ
  //   Printer? targetPrinter;

  //   if (cashierPrinterUrl != null) {
  //     final printers = await Printing.listPrinters();
  //     try {
  //       targetPrinter = printers.firstWhere((p) => p.url == cashierPrinterUrl);
  //     } catch (e) {
  //       // الطابعة مفصولة أو ممسوحة من النظام
  //     }
  //   }

  //   if (targetPrinter != null) {
  //     // 1️⃣ طباعة مباشرة بالخلفية للكاشير بدون ما تطلع نافذة
  //     await Printing.directPrintPdf(
  //       printer: targetPrinter,
  //       onLayout: (PdfPageFormat format) async => pdf.save(),
  //       name: 'Receipt_${widget.tableNumber}',
  //     );
  //   } else {
  //     // 2️⃣ إذا الكاشير بعده ما محدد طابعة، نفتحله النافذة العادية كاحتياط
  //     await Printing.layoutPdf(
  //       onLayout: (PdfPageFormat format) async => pdf.save(),
  //       name: 'Receipt_${widget.tableNumber}',
  //     );
  //   }
  // }

// دالة لاختيار الطابعة وحفظها
  Future<void> _setupPrinter(String printerRole, String prefsKey) async {
    // تفتح نافذة اختيار الطابعات الموجودة بالنظام
    final printer = await Printing.pickPrinter(
      context: context,
      title: "اختر طابعة",
    );

    if (printer != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, printer.url); // نحفظ مسار الطابعة

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم تعيين طابعة $printerRole بنجاح: ${printer.name}'),
          backgroundColor: Colors.green,
        ));
      }
    }
  }

  void _printReceipt() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Center(
            child: Text("معاينة الفاتورة",
                style: TextStyle(fontWeight: FontWeight.bold))),
        content: SizedBox(
            width: 300,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text("المجموع النهائي: $_finalPrice دينار",
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green))
            ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("إغلاق")),
          ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _printActualReceipt();
              },
              icon: const Icon(Icons.print),
              label: const Text("طباعة الوصل")),
        ],
      ),
    );
  }

  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("إضافة جهاز لهذه الطاولة",
            style:
                TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.gamepad, color: Colors.blue),
              title: const Text("إضافة PS4"),
              onTap: () async {
                await DatabaseHelper.instance
                    .addExtraTimer(widget.tableNumber, 'PS4');
                Navigator.pop(context);
                _loadTimers();
              },
            ),
            ListTile(
              leading: const Icon(Icons.gamepad, color: Colors.indigo),
              title: const Text("إضافة PS5"),
              onTap: () async {
                await DatabaseHelper.instance
                    .addExtraTimer(widget.tableNumber, 'PS5');
                Navigator.pop(context);
                _loadTimers();
              },
            ),
            ListTile(
              leading: const Icon(Icons.ballot, color: Colors.orange),
              title: const Text("إضافة بليارد"),
              onTap: () async {
                await DatabaseHelper.instance
                    .addExtraTimer(widget.tableNumber, 'بليارد');
                Navigator.pop(context);
                _loadTimers();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayedProducts = _selectedCategory == 'الكل'
        ? _products
        : _products.where((p) => p['category'] == _selectedCategory).toList();
    String title = widget.isGamingTable
        ? "🎮 طاولة ألعاب ${widget.tableNumber}"
        : (widget.tableNumber == 0
            ? "طلب سَفَري"
            : "طاولة رقم ${widget.tableNumber}");

    return Scaffold(
      appBar: AppBar(
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor:
              widget.isGamingTable ? Colors.purple[400] : Colors.orange[300],
          foregroundColor: Colors.white),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                if (widget.isGamingTable)
                  SizedBox(
                    height: 125,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _timers.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _timers.length) {
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                                color: Colors.purple[100],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                    color: Colors.purple,
                                    style: BorderStyle.solid)),
                            child: IconButton(
                              icon: const Icon(Icons.add_circle,
                                  size: 40, color: Colors.purple),
                              onPressed: _showAddDeviceDialog,
                              tooltip: "إضافة جهاز آخر",
                            ),
                          );
                        }

                        return SubTimerCard(
                          timerData: _timers[index],
                          onAddToCart: (name, price) {
                            _addToCart({'name': name, 'price': price});
                            _loadTimers();
                          },
                          onDeleteTimer: () async {
                            await DatabaseHelper.instance
                                .deleteTimer(_timers[index]['id']);
                            _loadTimers();
                          },
                        );
                      },
                    ),
                  ),
                Container(
                  height: 60,
                  color: Colors.grey[100],
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dbCategories.length,
                    itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ChoiceChip(
                            label: Text(_dbCategories[index]),
                            selected: _dbCategories[index] == _selectedCategory,
                            onSelected: (s) {
                              setState(() {
                                _selectedCategory = _dbCategories[index];
                              });
                            })),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.85),
                    itemCount: displayedProducts.length,
                    itemBuilder: (context, index) {
                      final product = displayedProducts[index];
                      String? imgPath = product['image_path'];
                      return InkWell(
                        onTap: () => _addToCart(product),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          elevation: 3,
                          child: Column(
                            children: [
                              Expanded(
                                  flex: 3,
                                  child: imgPath != null &&
                                          File(imgPath).existsSync()
                                      ? Image.file(File(imgPath),
                                          width: double.infinity,
                                          fit: BoxFit.cover)
                                      : Container(
                                          width: double.infinity,
                                          color: Colors.orange[50],
                                          child: const Icon(Icons.fastfood,
                                              size: 40, color: Colors.orange))),
                              Expanded(
                                  flex: 2,
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(product['name'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13),
                                            textAlign: TextAlign.center,
                                            maxLines: 1),
                                        Text("${product['price']}",
                                            style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold))
                                      ])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // ================= الفاتورة =================
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const Padding(
                    padding: EdgeInsets.all(15),
                    child: Text("الفاتورة",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold))),
                Expanded(
                  child: ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      bool isGameProduct =
                          item['name'].toString().startsWith('لعب');
                      return Card(
                        child: ListTile(
                          title: Text(item['name'],
                              style: TextStyle(
                                  color: isGameProduct
                                      ? Colors.purple
                                      : Colors.black,
                                  fontWeight:
                                      isGameProduct ? FontWeight.bold : null,
                                  fontSize: 12)),
                          subtitle: Text("${item['price'] * item['quantity']}"),
                          trailing: isGameProduct
                              ? IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _cart.removeAt(index);
                                    });
                                    _autoSaveCart();
                                  })
                              : Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(
                                      icon: const Icon(Icons.remove_circle),
                                      onPressed: () {
                                        setState(() {
                                          if (item['quantity'] > 1) {
                                            item['quantity']--;
                                          } else {
                                            _cart.removeAt(index);
                                          }
                                        });
                                        _autoSaveCart();
                                      }),
                                  Text("${item['quantity']}"),
                                  IconButton(
                                      icon: const Icon(Icons.add_circle),
                                      onPressed: () {
                                        setState(() {
                                          item['quantity']++;
                                        });
                                        _autoSaveCart();
                                      }),
                                ]),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      if (_discount > 0) ...[
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("المجموع:"),
                              Text("$_subTotal")
                            ]),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("الخصم:",
                                  style: TextStyle(color: Colors.red)),
                              Text("$_discount -",
                                  style: const TextStyle(color: Colors.red))
                            ]),
                        const Divider(),
                      ],

                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("النهائي:",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("$_finalPrice",
                                style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold))
                          ]),

                      Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed:
                                  _cart.isEmpty ? null : _showDiscountDialog,
                              child: const Text("خصم/تعديل"))),

                      // 👇 التعديل الثالث: زر طباعة طلب الشيف 👇
                      SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white),
                              onPressed:
                                  _cart.isEmpty ? null : _printChefReceipt,
                              icon: const Icon(Icons.soup_kitchen),
                              label: const Text("طباعة طلب الشيف",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)))),
                      const SizedBox(height: 10),

                      SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white),
                              onPressed: _cart.isEmpty ? null : _printReceipt,
                              icon: const Icon(Icons.receipt_long),
                              label: const Text("طباعة الفاتورة",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)))),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                              child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white),
                                  onPressed: _cart.isEmpty
                                      ? null
                                      : _showConfirmPaymentDialog,
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text("تأكيد الدفع"))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white),
                                  onPressed:
                                      _cart.isEmpty ? null : _cancelOrder,
                                  icon: const Icon(Icons.cancel),
                                  label: const Text("إلغاء"))),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= 👇 ويدجت العداد المصغر 👇 =================
class SubTimerCard extends StatefulWidget {
  final Map<String, dynamic> timerData;
  final Function(String name, double price) onAddToCart;
  final VoidCallback onDeleteTimer;

  const SubTimerCard(
      {required this.timerData,
      required this.onAddToCart,
      required this.onDeleteTimer,
      super.key});

  @override
  State<SubTimerCard> createState() => _SubTimerCardState();
}

class _SubTimerCardState extends State<SubTimerCard> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isPlaying = false;
  String _mode = 'single';

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.timerData['is_playing'] == 1;
    _mode = widget.timerData['mode'] ?? 'single';
    _elapsedSeconds = widget.timerData['accumulated_seconds'] ?? 0;

    if (_isPlaying && widget.timerData['start_time'] != null) {
      DateTime st = DateTime.parse(widget.timerData['start_time']);
      _elapsedSeconds += DateTime.now().difference(st).inSeconds;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play() async {
    setState(() => _isPlaying = true);
    await DatabaseHelper.instance.updateTimer(widget.timerData['id'], 1, _mode,
        DateTime.now().toIso8601String(), _elapsedSeconds);
    _startTimer();
  }

  void _pause() async {
    _timer?.cancel();
    setState(() => _isPlaying = false);
    await DatabaseHelper.instance
        .updateTimer(widget.timerData['id'], 0, _mode, null, _elapsedSeconds);
  }

  void _toggleMode() async {
    if (_isPlaying) return;
    setState(() => _mode = _mode == 'single' ? 'multi' : 'single');
    await DatabaseHelper.instance
        .updateTimer(widget.timerData['id'], 0, _mode, null, _elapsedSeconds);
  }

  void _stopAndAdd() async {
    _pause();
    final prefs = await SharedPreferences.getInstance();
    String dev = widget.timerData['device_name'];
    double pricePerHour = 0;

    if (dev == 'PS4') {
      pricePerHour =
          prefs.getDouble(_mode == 'single' ? 'ps4_single' : 'ps4_multi') ??
              2000;
    } else if (dev == 'PS5') {
      pricePerHour =
          prefs.getDouble(_mode == 'single' ? 'ps5_single' : 'ps5_multi') ??
              3000;
    } else {
      pricePerHour =
          prefs.getDouble(_mode == 'single' ? 'bill_single' : 'bill_multi') ??
              4000;
    }

    double exact = (_elapsedSeconds / 3600.0) * pricePerHour;
    double finalPrice = exact.roundToDouble();

    if (finalPrice > 0) {
      String modeText = _mode == 'single' ? 'فردي' : 'زوجي';
      int h = _elapsedSeconds ~/ 3600;
      int m = (_elapsedSeconds % 3600) ~/ 60;
      String timeStr =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

      widget.onAddToCart("لعب $dev $modeText - $timeStr", finalPrice);
    }

    await DatabaseHelper.instance.resetTimer(widget.timerData['id']);
    setState(() {
      _elapsedSeconds = 0;
      _mode = 'single';
    });
  }

  @override
  Widget build(BuildContext context) {
    int h = _elapsedSeconds ~/ 3600;
    int m = (_elapsedSeconds % 3600) ~/ 60;
    int s = _elapsedSeconds % 60;
    String time =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: _isPlaying ? Colors.purple[50] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: _isPlaying ? Colors.purple : Colors.grey[300]!)),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.timerData['device_name'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 10),
                  InkWell(
                      onTap: _toggleMode,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: _mode == 'single'
                                  ? Colors.blue[100]
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(5)),
                          child: Text(_mode == 'single' ? "فردي" : "زوجي",
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)))),
                ],
              ),
              const SizedBox(height: 5),
              Text(time,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _isPlaying ? Colors.red : Colors.black,
                      fontFamily: 'monospace')),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                      icon: Icon(
                          _isPlaying ? Icons.pause_circle : Icons.play_circle,
                          color: _isPlaying ? Colors.orange : Colors.green,
                          size: 30),
                      onPressed: _isPlaying ? _pause : _play,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints()),
                  IconButton(
                      icon: const Icon(Icons.add_shopping_cart,
                          color: Colors.red, size: 28),
                      onPressed: _elapsedSeconds > 0 && !_isPlaying
                          ? _stopAndAdd
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints()),
                ],
              )
            ],
          ),
          if (!_isPlaying && _elapsedSeconds == 0)
            Positioned(
              top: -10,
              right: -10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                onPressed: widget.onDeleteTimer,
              ),
            ),
        ],
      ),
    );
  }
}
