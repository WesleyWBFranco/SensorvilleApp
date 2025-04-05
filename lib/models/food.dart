import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String name;
  final double price;
  final String imagePath;
  final String description;
  final int quantity;
  final String category;
  final DateTime? addedDate; 
  final DateTime? expiryDate; 
  final bool isPromotional;

  Food({
    required this.name,
    required this.price,
    required this.imagePath,
    required this.description,
    required this.quantity,
    required this.category,
    this.addedDate, 
    this.expiryDate, 
    this.isPromotional = false,
  });

  static Food fromJson(Map<String, dynamic> json) {
    return Food(
      name: json['name'] as String? ?? '', 
      price: (json['price'] as num?)?.toDouble() ?? 0.0, 
      quantity: json['quantity'] as int? ?? 0, 
      imagePath: json['imagePath'] as String? ?? '', 
      description: json['description'] as String? ?? '', 
      category: json['category'] as String? ?? '', 
      addedDate: (json['addedDate'] as Timestamp?)?.toDate(), 
      expiryDate: (json['expiryDate'] as Timestamp?)?.toDate(), 
      isPromotional: json['isPromotional'] as bool? ?? false, 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'imagePath': imagePath,
      'description': description,
      'quantity': quantity,
      'category': category,
      'addedDate': addedDate != null ? Timestamp.fromDate(addedDate!) : null, 
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null, 
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
      addedDate: map['addedDate'] != null ? (map['addedDate'] as Timestamp).toDate() : null,
      expiryDate: map['expiryDate'] != null ? (map['expiryDate'] as Timestamp).toDate() : null, 
      isPromotional: map['isPromotional'] ?? false,
    );
  }
}