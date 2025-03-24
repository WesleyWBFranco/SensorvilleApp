import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
          appBar: AppBar(title: Text('Meu Carrinho')),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: value.getUserCart().length,
                    itemBuilder: (context, index) {
                      return CartItem(item: value.getUserCart()[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton:
              value.getUserCart().isNotEmpty
                  ? FloatingActionButton.extended(
                    onPressed: () {
                      _showConfirmationDialog(context, value, total);
                    },
                    label: Text(
                      'Confirmar pedido (R\$ ${total.toStringAsFixed(2)})',
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
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmar Pedido'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tem certeza que deseja efetuar o pedido?'),
              SizedBox(height: 10),
              Text('Valor Total: R\$ ${total.toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Não'),
            ),
            ElevatedButton(
              onPressed: () {
                _confirmOrder(context, cart, total);
                Navigator.pop(context);
              },
              child: Text('Sim'),
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

      // Atualizar estoque e registrar pedido
      for (var item in userCart) {
        final food = item['food'] as Food;
        final quantity = item['quantity'] as int;
        final foodDocRef = FirebaseFirestore.instance
            .collection('foods')
            .doc(food.id);
        final foodDoc = await foodDocRef.get();

        if (foodDoc.exists) {
          print("✅ Documento ${food.id} encontrado. Atualizando estoque...");
          batch.update(foodDocRef, {
            'quantity': foodDoc['quantity'] - quantity,
          });
        } else {
          print("❌ Documento ${food.id} não encontrado no Firestore!");
          allItemsExist = false;
        }
      }

      if (!allItemsExist) {
        ScaffoldMessenger.of(context).showSnackBar(
          // Use o contexto diretamente
          SnackBar(
            content: Text(
              'Erro: Alguns itens do pedido não estão disponíveis.',
            ),
          ),
        );
        return;
      }

      // Registrar o pedido
      final pedidoDocRef = pedidosCollection.doc();
      batch.set(pedidoDocRef, {
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

      // Limpar o carrinho
      cart.clearCart();

      // Exibir mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido confirmado com sucesso!')),
      ); // Use o contexto diretamente
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuário não logado. Faça login para continuar.'),
        ),
      ); // Use o contexto diretamente
    }
  }
}
