import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import 'add_food_dialog.dart';

class AdminShopPage extends StatelessWidget {
  const AdminShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Loja'),
      ),
      body: FutureBuilder(
        future: Provider.of<Cart>(context, listen: false).getFoodList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final food = snapshot.data![index];
                return ListTile(
                  title: Text(food.name),
                  subtitle: Text('R\$ ${food.price}'),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddFoodDialog(),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}