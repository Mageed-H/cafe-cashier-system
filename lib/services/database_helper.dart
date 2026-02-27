// ignore_for_file: empty_catches

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_system_v8.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    sqfliteFfiInit();
    final dbFactory = databaseFactoryFfi;
    final appStorage = await getApplicationSupportDirectory();
    final path = join(appStorage.path, filePath);

    return await dbFactory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: _createDB,
            onOpen: (db) async {
              await db.execute(
                  'CREATE TABLE IF NOT EXISTS categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)');
              var res =
                  await db.rawQuery('SELECT COUNT(*) as count FROM categories');
              if (((res.first['count'] as int?) ?? 0) == 0) {
                for (String c in [
                  'مشروبات ساخنة',
                  'مشروبات باردة',
                  'حلويات',
                  'طعام',
                  'أخرى'
                ]) {
                  await db.insert('categories', {'name': c});
                }
              }

              await db.execute(
                  'CREATE TABLE IF NOT EXISTS expenses (id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL NOT NULL, description TEXT NOT NULL, expense_date TEXT NOT NULL)');

              await db.execute(
                  'CREATE TABLE IF NOT EXISTS gaming_tables (id INTEGER PRIMARY KEY AUTOINCREMENT, table_number INTEGER NOT NULL UNIQUE)');

              await db.execute('''
              CREATE TABLE IF NOT EXISTS gaming_timers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                table_number INTEGER NOT NULL,
                device_name TEXT NOT NULL,         
                mode TEXT DEFAULT 'single',        
                is_playing INTEGER DEFAULT 0,      
                start_time TEXT,                   
                accumulated_seconds INTEGER DEFAULT 0 
              )
            ''');
            }));
  }

  Future _createDB(Database db, int version) async {
    await db.execute(
        '''CREATE TABLE tables (id INTEGER PRIMARY KEY AUTOINCREMENT, table_number INTEGER NOT NULL, status TEXT DEFAULT "available")''');
    await db.execute(
        '''CREATE TABLE products (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, price REAL NOT NULL, category TEXT, image_path TEXT)''');
    await db.execute('''
  CREATE TABLE orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT, 
    table_number INTEGER NOT NULL, 
    product_id INTEGER NOT NULL, 
    product_name TEXT NOT NULL, 
    price REAL NOT NULL, 
    quantity INTEGER NOT NULL, 
    is_paid INTEGER DEFAULT 0, 
    receipt_id TEXT, 
    payment_date TEXT,
    order_type TEXT NOT NULL DEFAULT 'cafeteria',
    printed_quantity INTEGER DEFAULT 0 -- 👇 هذا العمود الجديد
  )
''');
  }

  // ================= دوال الكافتريا =================
  Future<int> addExpense(double amount, String desc) async {
    final db = await instance.database;
    return await db.insert('expenses', {
      'amount': amount,
      'description': desc,
      'expense_date': DateTime.now().toString().substring(0, 16)
    });
  }

  Future<List<Map<String, dynamic>>> getExpenses({String? date}) async {
    final db = await instance.database;
    if (date != null) {
      return await db.query('expenses',
          where: 'expense_date LIKE ?',
          whereArgs: ['$date%'],
          orderBy: 'id DESC');
    }
    return await db.query('expenses', orderBy: 'id DESC');
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'id ASC');
    return result.map((c) => c['name'] as String).toList();
  }

  Future<int> addCategory(String name) async {
    final db = await instance.database;
    try {
      return await db.insert('categories', {'name': name});
    } catch (e) {
      return -1;
    }
  }

  Future<void> updateCategory(String oldName, String newName) async {
    final db = await instance.database;
    await db.update('categories', {'name': newName},
        where: 'name = ?', whereArgs: [oldName]);
    await db.update('products', {'category': newName},
        where: 'category = ?', whereArgs: [oldName]);
  }

  Future<int> deleteCategory(String name) async {
    final db = await instance.database;
    await db.update('products', {'category': 'أخرى'},
        where: 'category = ?', whereArgs: [name]);
    return await db.delete('categories', where: 'name = ?', whereArgs: [name]);
  }

  Future<int> addTable(int number) async {
    final db = await instance.database;
    return await db.insert('tables', {'table_number': number});
  }

  Future<List<Map<String, dynamic>>> getTables() async {
    final db = await instance.database;
    return await db.query('tables', orderBy: 'table_number');
  }

  Future<int> deleteTable(int id) async {
    final db = await instance.database;
    return await db.delete('tables', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addProduct(Map<String, dynamic> product) async {
    final db = await instance.database;
    return await db.insert('products', product);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'id DESC');
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateProduct(int id, String name, double price, String category,
      String? imagePath) async {
    final db = await instance.database;
    return await db.update(
        'products',
        {
          'name': name,
          'price': price,
          'category': category,
          'image_path': imagePath
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  // 👇 التعديل هنا لضمان حفظ الكمية المطبوعة 👇
  Future<void> saveUnpaidCart(
      int tableNumber, List<Map<String, dynamic>> cart, String type) async {
    final db = await instance.database;

    await db.delete('orders',
        where: 'table_number = ? AND is_paid = 0 AND order_type = ?',
        whereArgs: [tableNumber, type]);

    for (var item in cart) {
      await db.insert('orders', {
        'table_number': tableNumber,
        'product_id': item['id'],
        'product_name': item['name'],
        'price': item['price'],
        'quantity': item['quantity'],
        'is_paid': 0,
        'order_type': type,
        'printed_quantity': item['printed_quantity'] ?? 0 // حفظ الكمية المطبوعة
      });
    }
  }

  // 👇 التعديل هنا لضمان استرجاع الكمية المطبوعة مع الطلب 👇
  Future<List<Map<String, dynamic>>> getUnpaidCart(
      int tableNumber, String type) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('orders',
        where: 'table_number = ? AND is_paid = 0 AND order_type = ?',
        whereArgs: [tableNumber, type]);

    return List.generate(maps.length, (i) {
      return {
        'id': maps[i]['product_id'],
        'name': maps[i]['product_name'],
        'price': maps[i]['price'],
        'quantity': maps[i]['quantity'],
        'printed_quantity':
            maps[i]['printed_quantity'] ?? 0 // استرجاع الكمية المطبوعة
      };
    });
  }

  Future<void> confirmPayment(int tableNumber, String type) async {
    final db = await instance.database;
    await db.update(
        'orders',
        {
          'is_paid': 1,
          'receipt_id': DateTime.now().millisecondsSinceEpoch.toString(),
          'payment_date': DateTime.now().toString().substring(0, 16)
        },
        where: 'table_number = ? AND is_paid = 0 AND order_type = ?',
        whereArgs: [tableNumber, type]);
  }

  Future<bool> isTableBusy(int tableNumber, String type) async {
    final db = await instance.database;
    final result = await db.query('orders',
        where: 'table_number = ? AND is_paid = 0 AND order_type = ?',
        whereArgs: [tableNumber, type],
        limit: 1);
    return result.isNotEmpty;
  }

  Future<void> clearTableOrders(int tableNumber, String type) async {
    final db = await instance.database;
    await db.delete('orders',
        where: 'table_number = ? AND is_paid = 0 AND order_type = ?',
        whereArgs: [tableNumber, type]);
  }

  Future<void> clearCashRegister() async {
    final db = await instance.database;
    await db.delete('orders', where: 'is_paid = 1');
    await db.delete('expenses');
  }

  Future<List<Map<String, dynamic>>> getPaidOrders({String? date}) async {
    final db = await instance.database;
    if (date != null) {
      return await db.query('orders',
          where: 'is_paid = 1 AND payment_date LIKE ?',
          whereArgs: ['$date%'],
          orderBy: 'id DESC');
    } else {
      return await db.query('orders', where: 'is_paid = 1', orderBy: 'id DESC');
    }
  }

  // ================= دوال طاولات الألعاب والعدادات =================
  Future<List<Map<String, dynamic>>> getGamingTables() async {
    final db = await instance.database;
    return await db.query('gaming_tables', orderBy: 'table_number ASC');
  }

  Future<void> addGamingTable(int number) async {
    final db = await instance.database;
    try {
      await db.insert('gaming_tables', {'table_number': number});
      await db.insert(
          'gaming_timers', {'table_number': number, 'device_name': 'PS4'});
      await db.insert(
          'gaming_timers', {'table_number': number, 'device_name': 'PS5'});
      await db.insert(
          'gaming_timers', {'table_number': number, 'device_name': 'بليارد'});
    } catch (e) {}
  }

  Future<void> deleteGamingTable(int number) async {
    final db = await instance.database;
    await db.delete('gaming_tables',
        where: 'table_number = ?', whereArgs: [number]);
    await db.delete('gaming_timers',
        where: 'table_number = ?', whereArgs: [number]);
  }

  Future<List<Map<String, dynamic>>> getTimersForTable(int tableNumber) async {
    final db = await instance.database;
    return await db.query('gaming_timers',
        where: 'table_number = ?', whereArgs: [tableNumber]);
  }

  Future<void> updateTimer(int id, int isPlaying, String mode,
      String? startTime, int accumulatedSeconds) async {
    final db = await instance.database;
    await db.update(
        'gaming_timers',
        {
          'is_playing': isPlaying,
          'mode': mode,
          'start_time': startTime,
          'accumulated_seconds': accumulatedSeconds
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<void> resetTimer(int id) async {
    final db = await instance.database;
    await db.update(
        'gaming_timers',
        {
          'is_playing': 0,
          'start_time': null,
          'accumulated_seconds': 0,
          'mode': 'single'
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  // ================= دوال العدادات الإضافية =================
  Future<void> addExtraTimer(int tableNumber, String deviceName) async {
    final db = await instance.database;
    await db.insert('gaming_timers', {
      'table_number': tableNumber,
      'device_name': deviceName,
      'mode': 'single',
      'is_playing': 0,
      'accumulated_seconds': 0
    });
  }

  Future<void> deleteTimer(int timerId) async {
    final db = await instance.database;
    await db.delete('gaming_timers', where: 'id = ?', whereArgs: [timerId]);
  }
}
