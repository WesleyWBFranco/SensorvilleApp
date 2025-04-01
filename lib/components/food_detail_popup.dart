import 'dart:io';
import 'package:flutter/material.dart';
import '../models/food.dart';

class FoodDetailPopup extends StatelessWidget {
  final Food food;
  final String id;
  final Function(Food, String) onAddToCart;

  const FoodDetailPopup({
    super.key,
    required this.food,
    required this.id,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.white,
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
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
              const SizedBox(height: 16),
              Text(
                food.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(food.description),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'R\$ ${food.price}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 5.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Fechar',
                            style: TextStyle(color: Colors.amber),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                        ),
                        onPressed: () => onAddToCart(food, id),
                        child: const Text(
                          'Adicionar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
