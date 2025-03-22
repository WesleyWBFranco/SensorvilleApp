import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Importe o pacote uuid
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
                // Adicione a verificação para o campo 'id'
                final id =
                    data['id'] ??
                    doc.id; // Tenta usar 'id' do Firestore, senão usa doc.id
                return Food.fromMap(data, id);
              } catch (e) {
                print(
                  'getFoodList: Erro ao converter documento ${doc.id} para Food: $e',
                );
                return Food(
                  id: const Uuid().v4(), // Gera um UUID em caso de erro
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
                id: const Uuid().v4(), // Gera um UUID em caso de erro
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
      return []; // Retorna uma lista vazia em caso de erro
    }
  }

  List<Map<String, dynamic>> getUserCart() {
    return _userCart.values.toList();
  }

  void addItemToCart(Food food) {
    if (_userCart.containsKey(food.id)) {
      _userCart.update(
        food.id,
        (value) => {'food': food, 'quantity': (value['quantity'] as int) + 1},
      );
    } else {
      _userCart[food.id] = {'food': food, 'quantity': 1};
    }
    notifyListeners();
  }

  void removeItemFromCart(Food food) {
    if (_userCart.containsKey(food.id)) {
      final item = _userCart[food.id]; // Armazena o item em uma variável local
      if (item != null) {
        // Verifica se item não é nulo
        final quantity =
            item['quantity'] as int?; // Obtém a quantidade, permitindo nulo
        if (quantity != null && quantity > 1) {
          // Verifica se a quantidade não é nula e é maior que 1
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
}
