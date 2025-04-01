import 'dart:io';
import 'package:flutter/material.dart';
import '../models/food.dart';

class FoodTile extends StatelessWidget {
  Food food;
  void Function()? onTap;
  FoodTile({super.key, required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
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

                Text(
                  food.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 7.0),
                  child: Text(
                    'R\$ ${food.price}',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
