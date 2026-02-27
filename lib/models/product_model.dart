class Product {
  final int? id;
  final String name;
  final double price;
  final String category;

  Product({this.id, required this.name, required this.price, required this.category});

  // تحويل البيانات من Map (قاعدة البيانات) إلى Object
  factory Product.fromMap(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    price: json['price'],
    category: json['category'],
  );

  // تحويل الـ Object إلى Map لخزنه في قاعدة البيانات
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price': price,
    'category': category,
  };
}