import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'food.dart';

class Cart extends ChangeNotifier {
  final CollectionReference foodCollection = FirebaseFirestore.instance
      .collection('foods');

  List<Food> foodShop = [];
  Map<String, Map<String, dynamic>> _userCart = {};

  Future<List<Food>> getFoodList() async {
    print('getFoodList: Iniciando consulta ao Firestore...');
    try {
      final snapshot = await foodCollection.get();
      print('getFoodList: Consulta ao Firestore concluída.');
      foodShop =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null) {
              try {
                print(
                  'getFoodList: Convertendo documento ${doc.id} para Food...',
                );
                final id = data['id'] ?? doc.id;
                return Food.fromMap(data, id);
              } catch (e) {
                print(
                  'getFoodList: Erro ao converter documento ${doc.id} para Food: $e',
                );
                return Food(
                  id: const Uuid().v4(),
                  name: 'Erro',
                  price: 0.0,
                  imagePath: 'erro',
                  description: 'Erro',
                  quantity: 0,
                  category: 'Erro',
                  addedDate: DateTime.now(),
                  expiryDate: DateTime.now(),
                );
              }
            } else {
              print('getFoodList: Documento ${doc.id} com dados nulos.');
              return Food(
                id: const Uuid().v4(),
                name: 'Erro',
                price: 0.0,
                imagePath: 'erro',
                description: 'Erro',
                quantity: 0,
                category: 'Erro',
                addedDate: DateTime.now(),
                expiryDate: DateTime.now(),
              );
            }
          }).toList();
      print('getFoodList: Lista de Food criada com ${foodShop.length} itens.');
      notifyListeners();
      return foodShop;
    } catch (e) {
      print('getFoodList: Erro na consulta ao Firestore: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> getUserCart() {
    return _userCart.values.toList();
  }

  void addItemToCart(Food food) {
    if (_userCart.containsKey(food.id)) {
      final currentQuantity = _userCart[food.id]?['quantity'] as int? ?? 0;
      if (currentQuantity < food.quantity) {
        _userCart.update(
          food.id,
          (value) => {'food': food, 'quantity': currentQuantity + 1},
        );
      }
    } else {
      _userCart[food.id] = {'food': food, 'quantity': 1};
    }
    notifyListeners();
  }

  void removeItemFromCart(Food food) {
    if (_userCart.containsKey(food.id)) {
      final item = _userCart[food.id];
      if (item != null) {
        final quantity = item['quantity'] as int?;
        if (quantity != null && quantity > 1) {
          _userCart.update(
            food.id,
            (value) => {'food': food, 'quantity': quantity - 1},
          );
        } else {
          _userCart.remove(food.id);
        }
      }
    }
    notifyListeners();
  }

  Future<void> addFoodToFirestore(Food food) async {
    await foodCollection.add(food.toMap());
    notifyListeners();
  }

  // Adicione a função clearCart aqui
  void clearCart() {
    _userCart.clear();
    notifyListeners();
  }
}
