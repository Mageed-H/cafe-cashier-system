// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, List<Map<String, dynamic>>> _groupedInvoices = {};

  double _totalRevenue = 0.0;
  double _totalExpenses = 0.0; // متغير المصروفات
  int _totalItemsSold = 0;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() async {
    // نجيب الفواتير والمصروفات مال هذا اليوم
    final orders =
        await DatabaseHelper.instance.getPaidOrders(date: _selectedDate);
    final expensesList =
        await DatabaseHelper.instance.getExpenses(date: _selectedDate);

    double revenue = 0.0;
    double exps = 0.0;
    int items = 0;
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var order in orders) {
      revenue += (order['price'] * order['quantity']);
      items += (order['quantity'] as int);
      String rId = order['receipt_id'] ?? 'فاتورة_قديمة';
      if (!grouped.containsKey(rId)) grouped[rId] = [];
      grouped[rId]!.add(order);
    }

    // حساب مجموع المصروفات
    for (var e in expensesList) {
      exps += e['amount'];
    }

    setState(() {
      _totalRevenue = revenue;
      _totalExpenses = exps;
      _totalItemsSold = items;
      _groupedInvoices = grouped;
    });
  }

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Colors.orange)),
          child: child!),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked.toString().substring(0, 10);
      });
      _loadStatistics();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
    _loadStatistics();
  }

  @override
  Widget build(BuildContext context) {
    // 👇 حساب الصافي الموجود بالدرج فعلياً 👇
    double netCash = _totalRevenue - _totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text("الإحصائيات والصندوق"),
        backgroundColor: Colors.orange[300],
        actions: [
          IconButton(
              tooltip: "تحديد تاريخ معين",
              icon: const Icon(Icons.calendar_month, color: Colors.black87),
              onPressed: _pickDate),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // ================= البطاقات الثلاثة (مبيعات، سحوبات، الصافي) =================
            Row(
              children: [
                Expanded(
                    child: Card(
                        color: Colors.green[50],
                        child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(children: [
                              const Text("المبيعات",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                              Text("$_totalRevenue",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold))
                            ])))),
                Expanded(
                    child: Card(
                        color: Colors.red[50],
                        child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(children: [
                              const Text("المصروفات",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red)),
                              Text("$_totalExpenses",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold))
                            ])))),
                Expanded(
                    child: Card(
                        color: Colors.blue[50],
                        child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(children: [
                              const Text("الصافي بالدرج",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue)),
                              Text("$netCash",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold))
                            ])))),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    _selectedDate == null
                        ? "سجل كل الفواتير:"
                        : "فواتير يوم: $_selectedDate",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                if (_selectedDate != null)
                  TextButton.icon(
                      onPressed: _clearDateFilter,
                      icon:
                          const Icon(Icons.clear, color: Colors.red, size: 18),
                      label: const Text("عرض الكل",
                          style: TextStyle(color: Colors.red)))
              ],
            ),
            const Divider(thickness: 2),
            Expanded(
                child: _groupedInvoices.isEmpty
                    ? Center(
                        child: Text(
                            _selectedDate == null
                                ? "لا توجد مبيعات."
                                : "لا توجد فواتير في هذا اليوم.",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _groupedInvoices.length,
                        itemBuilder: (context, index) {
                          String receiptId =
                              _groupedInvoices.keys.elementAt(index);
                          List<Map<String, dynamic>> invoiceItems =
                              _groupedInvoices[receiptId]!;

                          double invoiceTotal = invoiceItems.fold(
                              0,
                              (sum, item) =>
                                  sum + (item['price'] * item['quantity']));
                          String date =
                              invoiceItems.first['payment_date'] ?? 'غير محدد';
                          int tableNo = invoiceItems.first['table_number'];

                          // 👇 هنا التعديل: نقرأ نوع الطلب من قاعدة البيانات 👇
                          String orderType =
                              invoiceItems.first['order_type'] ?? 'cafeteria';

                          // 👇 نحدد الاسم والأيقونة واللون بناءً على النوع 👇
                          String receiptTitle;
                          IconData tileIcon;
                          Color tileColor;

                          if (tableNo == 0) {
                            receiptTitle = "طلب سَفَري";
                            tileIcon = Icons.takeout_dining;
                            tileColor = Colors.green;
                          } else if (orderType == 'gaming') {
                            receiptTitle = "طاولة ألعاب ($tableNo)";
                            tileIcon = Icons.sports_esports; // أيقونة ألعاب
                            tileColor = Colors.purple; // لون بنفسجي للألعاب
                          } else {
                            receiptTitle = "طاولة رقم ($tableNo)";
                            tileIcon = Icons.receipt;
                            tileColor = Colors.orange;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              // نستخدم المتغيرات اللي جهزناها فوق
                              leading: CircleAvatar(
                                  backgroundColor: tileColor,
                                  child: Icon(tileIcon, color: Colors.white)),
                              title: Text(receiptTitle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text("الوقت: $date"),
                              trailing: Text("$invoiceTotal",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                      fontSize: 16)),
                              children: [
                                const Divider(thickness: 1),
                                Container(
                                  color: Colors.grey[50],
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 5),
                                  child: Column(
                                    children: invoiceItems
                                        .map((item) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                      "- ${item['product_name']} (x${item['quantity']})"),
                                                  Text(
                                                      "${item['price'] * item['quantity']} دينار",
                                                      style: const TextStyle(
                                                          color: Colors.grey))
                                                ])))
                                        .toList(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          );
                        },
                      )),
          ],
        ),
      ),
    );
  }
}
