import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String name;
  final double price;
  final String imagePath;
  final String description;
  final int quantity;
  final String category;
  final DateTime? addedDate; // 👈 Tornar nullable
  final DateTime? expiryDate; // 👈 Tornar nullable
  final bool isPromotional;

  Food({
    required this.name,
    required this.price,
    required this.imagePath,
    required this.description,
    required this.quantity,
    required this.category,
    this.addedDate, // 👈 Não mais 'required'
    this.expiryDate, // 👈 Não mais 'required'
    this.isPromotional = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'imagePath': imagePath,
      'description': description,
      'quantity': quantity,
      'category': category,
      'addedDate': addedDate != null ? Timestamp.fromDate(addedDate!) : null, // 👈 Lidar com null
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null, // 👈 Lidar com null
      'isPromotional': isPromotional,
    };
  }

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      name: map['name'],
      price: (map['price'] ?? 0.0).toDouble(),
      imagePath: map['imagePath'],
      description: map['description'],
      quantity: map['quantity'],
      category: map['category'],
      addedDate: map['addedDate'] != null ? (map['addedDate'] as Timestamp).toDate() : null, // 👈 Lidar com null
      expiryDate: map['expiryDate'] != null ? (map['expiryDate'] as Timestamp).toDate() : null, // 👈 Lidar com null
      isPromotional: map['isPromotional'] ?? false,
    );
  }
}