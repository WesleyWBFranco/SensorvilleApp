import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../components/cart_item.dart';
import '../models/cart.dart';
import '../models/food.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Cart>(
      builder: (context, value, child) {
        double total = 0;
        for (var item in value.getUserCart()) {
          total += item['food'].price * item['quantity'];
        }

        return Scaffold(
          backgroundColor: Colors.grey[200],
          body:
              value.getUserCart().isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.remove_shopping_cart,
                          color: Colors.amber,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Seu carrinho está vazio!',
                          style: TextStyle(fontSize: 18, color: Colors.amber),
                        ),
                      ],
                    ),
                  )
                  : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 160,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Lottie.asset("assets/animations/cart.json"),
                      ),

                      const Padding(
                        padding: EdgeInsets.only(
                          top: 10,
                          left: 25,
                          right: 25,
                          bottom: 10,
                        ),
                        child: Divider(color: Colors.white),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: value.getUserCart().length,
                                  itemBuilder: (context, index) {
                                    return CartItem(
                                      item: value.getUserCart()[index],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 25, left: 25, right: 25),
                        child: Divider(color: Colors.white),
                      ),
                    ],
                  ),
          floatingActionButton:
              value.getUserCart().isNotEmpty
                  ? FloatingActionButton.extended(
                    backgroundColor: Colors.amber,
                    onPressed: () {
                      _showConfirmationDialog(context, value, total);
                    },
                    label: Text(
                      'Confirmar Compra (R\$ ${total.toStringAsFixed(2)})',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                  : null,
        );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context, Cart cart, double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[200],
          title: Text('Confirmar Compra'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tem certeza que deseja efetuar a compra?',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                'Valor Total: R\$ ${total.toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 60),
              Text('Chave Pix para pagamento:', style: TextStyle(fontSize: 16)),
              SizedBox(height: 5),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'teste@gmail.com',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: Colors.amber),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: "teste@gmail.com"),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Chave Pix copiada!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar', style: TextStyle(color: Colors.amber)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () {
                _confirmOrder(context, cart, total);
                Navigator.pop(context);
              },
              child: Text(
                'Confirmar Compra',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmOrder(BuildContext context, Cart cart, double total) async {
    final userCart = cart.getUserCart();
    final batch = FirebaseFirestore.instance.batch();
    final pedidosCollection = FirebaseFirestore.instance.collection('pedidos');
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final userName =
          userData?['first name'] as String? ?? 'Nome Desconhecido';

      bool allItemsExist = true;

      for (var item in userCart) {
        final food = item['food'] as Food;
        final quantity = item['quantity'] as int;
        final foodId = item['id'];

        final foodDocRef = FirebaseFirestore.instance
            .collection('foods')
            .doc(foodId);
        final foodDoc = await foodDocRef.get();

        if (foodDoc.exists) {
          print("✅ Documento $foodId encontrado. Atualizando estoque...");
          batch.update(foodDocRef, {
            'quantity': foodDoc['quantity'] - quantity,
          });
        } else {
          print("❌ Documento $foodId não encontrado no Firestore!");
          allItemsExist = false;
        }
      }

      if (!allItemsExist) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro: Alguns itens do pedido não estão disponíveis.',
              ),
            ),
          );
        }
        return;
      }

      final pedidoDocRef = pedidosCollection.doc();
      batch.set(pedidoDocRef, {
        'userId': user.uid,
        'nome': userName,
        'data': DateTime.now(),
        'itens':
            userCart
                .map(
                  (item) => {
                    'nome': item['food'].name,
                    'quantidade': item['quantity'],
                    'preco': item['food'].price,
                  },
                )
                .toList(),
        'total': total,
      });

      await batch.commit();

      cart.clearCart();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pedido confirmado com sucesso!')),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuário não logado. Faça login para continuar.'),
          ),
        );
      }
    }
  }
}
