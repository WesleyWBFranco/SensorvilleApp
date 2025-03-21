import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'food.dart';

class Cart extends ChangeNotifier {
  final CollectionReference foodCollection =
      FirebaseFirestore.instance.collection('foods');

  List<Food> foodShop = [];
  List<Food> userCart = [];

  Future<List<Food>> getFoodList() async {
    final snapshot = await foodCollection.get();
    foodShop = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>?; // Cast para Map<String, dynamic>?
      if (data != null) {
        try {
          return Food.fromMap(data);
        } catch (e) {
          print('Erro ao converter documento para Food: $e');
          // Retorna um Food padrão ou lança uma exceção, dependendo do que você preferir
          return Food(
            name: 'Erro',
            price: 0.0,
            imagePath: 'erro',
            description: 'Erro',
            quantity: 0,
            category: 'Erro',
            addedDate: DateTime.now(),
            expiryDate: DateTime.now(),
          ); // Ou lance uma exceção aqui
        }
      } else {
        print('Documento com dados nulos: ${doc.id}');
        // Retorna um Food padrão ou lança uma exceção
        return Food(
          name: 'Erro',
          price: 0.0,
          imagePath: 'erro',
          description: 'Erro',
          quantity: 0,
          category: 'Erro',
          addedDate: DateTime.now(),
          expiryDate: DateTime.now(),
        ); // Ou lance uma exceção aqui
      }
    }).toList();
    notifyListeners();
    return foodShop;
  }

  List<Food> getUserCart() {
    return userCart;
  }

  void addItemToCart(Food food) {
    userCart.add(food);
    notifyListeners();
  }

  void removeItemFromCart(Food food) {
    userCart.remove(food);
    notifyListeners();
  }

  Future<void> addFoodToFirestore(Food food) async {
    await foodCollection.add(food.toMap());
    notifyListeners();
  }
}