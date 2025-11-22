class MenuItem {
  final String name;
  final double? price;

  MenuItem({required this.name, required this.price});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      name: map['Name'],
      price: map['price'].toDouble(),
    );
  }
}
