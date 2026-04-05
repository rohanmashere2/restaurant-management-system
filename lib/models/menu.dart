class MenuItem {
  final String name;
  final double? price;

  /// When false, waiter menu shows the item as 86 / unavailable.
  final bool available;

  MenuItem({
    required this.name,
    required this.price,
    this.available = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'available': available,
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      name: map['name'] ?? map['Name'],
      price: (map['price'] as num?)?.toDouble(),
      available: map['available'] != false,
    );
  }
}
