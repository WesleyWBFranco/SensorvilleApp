class Food {
  final String name;
  final double price;
  final String imagePath;
  final String description;
  final int quantity;
  final String category;
  final DateTime addedDate;
  final DateTime expiryDate;

  Food({
    required this.name,
    required this.price,
    required this.imagePath,
    required this.description,
    required this.quantity,
    required this.category,
    required this.addedDate,
    required this.expiryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'imagePath': imagePath,
      'description': description,
      'quantity': quantity,
      'category': category,
      'addedDate': addedDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
    };
  }

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      name: map['name'],
      price: map['price'].toDouble(),
      imagePath: map['imagePath'],
      description: map['description'],
      quantity: map['quantity'],
      category: map['category'],
      addedDate: DateTime.parse(map['addedDate']),
      expiryDate: DateTime.parse(map['expiryDate']),
    );
  }
}