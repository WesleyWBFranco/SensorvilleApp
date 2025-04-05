import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';

class CartItem extends StatelessWidget {
  final Map<String, dynamic> item;
  CartItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final food = item['food'] as dynamic;
    final id = item['id'] as String; 

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(
          8.0,
        ), 
        child: Row(
          children: [
          
            Container(
              width: 70.0,
              height: 70.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child:
                    food.imagePath.startsWith('http://') ||
                            food.imagePath.startsWith('https://')
                        ? Image.network(
                          food.imagePath,
                          cacheWidth: 280,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image_not_supported);
                          },
                        )
                        : food.imagePath.startsWith('/')
                        ? Image.file(
                          File(food.imagePath),
                          cacheWidth: 280,
                          fit: BoxFit.contain,
                        )
                        : Image.asset(
                          food.imagePath,
                          cacheWidth: 280,
                          fit: BoxFit.contain,
                        ),
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'R\$ ${(food.price * item['quantity']).toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
           
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    Provider.of<Cart>(
                      context,
                      listen: false,
                    ).removeItemFromCart(food, id);
                  },
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  child: Text(
                    '${item['quantity']}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (item['quantity'] < food.quantity) {
                      Provider.of<Cart>(
                        context,
                        listen: false,
                      ).addItemToCart(food, id);
                    } else {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Limite de itens disponíveis: ${food.quantity}',
                            ),
                          ),
                        );
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
