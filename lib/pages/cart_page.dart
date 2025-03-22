import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/cart_item.dart';
import '../models/cart.dart';

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
                    appBar: AppBar(
                        title: Text('Meu Carrinho'),
                    ),
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
                    floatingActionButton: FloatingActionButton.extended(
                        onPressed: () {
                            // Navegar para a tela de pagamento
                        },
                        label: Text('Confirmar pedido (R\$ ${total.toStringAsFixed(2)})'),
                    ),
                );
            },
        );
    }
}