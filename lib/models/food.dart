import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
    final String id;
    final String name;
    final double price;
    final String imagePath;
    final String description;
    final int quantity;
    final String category;
    final DateTime addedDate;
    final DateTime expiryDate;

    Food({
        required this.id,
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
            'id': id,
            'name': name,
            'price': price,
            'imagePath': imagePath,
            'description': description,
            'quantity': quantity,
            'category': category,
            'addedDate': Timestamp.fromDate(addedDate),
            'expiryDate': Timestamp.fromDate(expiryDate),
        };
    }

    factory Food.fromMap(Map<String, dynamic> map, String id) { // Adicione o parâmetro 'id'
        return Food(
            id: id, // Use o 'id' fornecido
            name: map['name'],
            price: map['price'].toDouble(),
            imagePath: map['imagePath'],
            description: map['description'],
            quantity: map['quantity'],
            category: map['category'],
            addedDate: (map['addedDate'] as Timestamp).toDate(),
            expiryDate: (map['expiryDate'] as Timestamp).toDate(),
        );
    }
}