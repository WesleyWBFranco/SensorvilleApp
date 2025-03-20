import 'package:flutter/material.dart';

import 'food.dart';

class Cart extends ChangeNotifier {
  // list of foods for sale
  List<Food> foodShop = [
    Food(
      name: 'Coca-Cola Original 350ml',
      price: '3,99',
      description: 'Lata 350ml',
      imagePath: 'lib/images/coca-lata.png',
    ),

    Food(
      name: 'Chocolate Bis Branco',
      price: '6,99',
      description: 'Caixa de chocolate Bis branco',
      imagePath: 'lib/images/bis-branco.png',
    ),

    Food(
      name: 'Chocolate Choco Amendoim Trento Allegro 35g',
      price: '2,49',
      description: 'Embalagem 35g',
      imagePath: 'lib/images/trento-allegro.png',
    ),

    Food(
      name: 'Chocolate Avelã Choco Branco Trento 32g',
      price: '1,99',
      description: 'Embalagem 32g',
      imagePath: 'lib/images/trento-avela-choco-branco.png',
    ),
  ];

  // list of items in user cart
  List<Food> userCart = [];

  // get list of foods for sale
  List<Food> getFoodList() {
    return foodShop;
  }

  // get cart
  List<Food> getUserCart() {
    return userCart;
  }

  // add items to cart
  void addItemToCart(Food food) {
    userCart.add(food);
    notifyListeners();
  }

  // remove items from cart
  void removeItemFromCart(Food food) {
    userCart.remove(food);
    notifyListeners();
  }
}
