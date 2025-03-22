import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../models/food.dart';

class CartItem extends StatelessWidget {
    final Map<String, dynamic> item; // Modificação aqui
    CartItem({super.key, required this.item}); // Modificação aqui

    @override
    Widget build(BuildContext context) {
        return Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
                leading: item['food'].imagePath.startsWith('/')
                    ? Image.file(File(item['food'].imagePath))
                    : Image.asset(item['food'].imagePath),
                title: Text(item['food'].name),
                subtitle: Text('R\$ ${(item['food'].price * item['quantity']).toStringAsFixed(2)}'),
                trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () {
                                Provider.of<Cart>(context, listen: false).removeItemFromCart(item['food']);
                            },
                        ),
                        Text('${item['quantity']}'),
                        IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                                if (item['quantity'] < item['food'].quantity) {
                                    Provider.of<Cart>(context, listen: false).addItemToCart(item['food']);
                                } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Limite de itens disponíveis: ${item['food'].quantity}')),
                                    );
                                }
                            },
                        ),
                    ],
                ),
            ),
        );
    }
}