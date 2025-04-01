import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

import 'food.dart';

class Cart extends ChangeNotifier {
  final CollectionReference foodCollection = FirebaseFirestore.instance
      .collection('foods');

  List<Map<String, dynamic>> foodShop = [];

  Map<String, Map<String, dynamic>> _userCart = {};

  Future<List<Map<String, dynamic>>> getFoodList() async {
    final QuerySnapshot querySnapshot = await foodCollection.get();

    final List<Map<String, dynamic>> foodList =
        querySnapshot.docs.map((doc) {
          final foodData = doc.data() as Map<String, dynamic>;

          final food = Food.fromMap(foodData);

          return {'food': food, 'id': doc.id};
        }).toList();

    foodShop = foodList;

    return foodList;
  }

  List<Map<String, dynamic>> getUserCart() {
    return _userCart.entries.map((entry) {
      return {
        'food': entry.value['food'],

        'quantity': entry.value['quantity'],

        'id': entry.key,
      };
    }).toList();
  }

  void addItemToCart(Food food, String id) {
    if (_userCart.containsKey(id)) {
      final currentItem = _userCart[id];

      if (currentItem != null) {
        final currentQuantity = currentItem['quantity'] as int;

        if (currentQuantity < food.quantity) {
          _userCart.update(
            id,

            (value) => {'food': food, 'quantity': currentQuantity + 1},
          );
        }
      }
    } else {
      _userCart[id] = {'food': food, 'quantity': 1};
    }

    notifyListeners();
  }

  void removeItemFromCart(Food food, String id) {
    if (_userCart.containsKey(id)) {
      final item = _userCart[id];

      if (item != null) {
        final quantity = item['quantity'] as int?;

        if (quantity != null && quantity > 1) {
          _userCart.update(
            id,

            (value) => {'food': food, 'quantity': quantity - 1},
          );
        } else {
          _userCart.remove(id);
        }
      }
    }

    notifyListeners();
  }

  Future<void> addFood(Food food) async {
    // 👈 Renomeado para addFood

    final docRef = await foodCollection.add(food.toMap());

    notifyListeners();
  }

  void clearCart() {
    _userCart.clear();

    notifyListeners();
  }

  Stream<List<Map<String, dynamic>>> getFoodListAsStream() {
    return foodCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();

            if (data is Map<String, dynamic>) {
              return {'food': Food.fromMap(data), 'id': doc.id};
            } else {
              return null;
            }
          })
          .where((item) => item != null)
          .cast<Map<String, dynamic>>()
          .toList();
    });
  }
}
