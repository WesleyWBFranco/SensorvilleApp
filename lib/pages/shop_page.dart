import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/food_tile.dart';
import '../models/cart.dart';
import '../models/food.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late Future<List<Food>> _foodListFuture; // Adicione esta linha

  @override
  void initState() {
    super.initState();
    _foodListFuture =
        Provider.of<Cart>(
          context,
          listen: false,
        ).getFoodList(); // Adicione esta linha
  }

  // add food to cart
  void addFoodToCart(Food food) {
    Provider.of<Cart>(context, listen: false).addItemToCart(food);

    // alert the user, food successfully added
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Adicionado com sucesso!'),
            content: Text('Abra seu carrinho!'),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Cart>(
      builder:
          (context, value, child) => Column(
            children: [
              // search bar
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pesquisar', style: TextStyle(color: Colors.grey)),
                    Icon(Icons.search, color: Colors.grey),
                  ],
                ),
              ),

              // message
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 25.0),
                child: Text(
                  'Deus é bom o tempo todo, o tempo todo Deus é bom!',
                  style: TextStyle(color: Colors.amber[900]),
                ),
              ),

              // hot picks
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Promoções ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      'Ver todos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // list of foods for sale
              Expanded(
                child: FutureBuilder<List<Food>>(
                  future: _foodListFuture, // Use _foodListFuture aqui
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      print('Carregando dados...');
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      print('Erro ao carregar dados: ${snapshot.error}');
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    } else if (snapshot.hasData) {
                      final foodList = snapshot.data!;
                      print('Dados carregados: ${foodList.length} itens');
                      return ListView.builder(
                        itemCount: foodList.length,
                        scrollDirection: Axis.horizontal,
                        cacheExtent: 200,
                        itemBuilder: (context, index) {
                          Food food = foodList[index];
                          return FoodTile(
                            food: food,
                            onTap: () => addFoodToCart(food),
                          );
                        },
                      );
                    } else {
                      print('Nenhum dado disponível.');
                      return Center(child: Text('Nenhum dado disponível.'));
                    }
                  },
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(top: 25, left: 25, right: 25),
                child: Divider(color: Colors.white),
              ),
            ],
          ),
    );
  }
}
