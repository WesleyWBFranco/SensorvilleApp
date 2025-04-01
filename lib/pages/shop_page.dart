import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/food_detail_popup.dart';
import '../components/food_tile.dart';
import '../models/cart.dart';
import '../models/food.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory = 'Todos';
  List<String> _categories = ['Todos'];
  Stream<List<Map<String, dynamic>>>? _foodStream;

  @override
  void initState() {
    super.initState();
    _foodStream =
        Provider.of<Cart>(context, listen: false).getFoodListAsStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // add food to cart
  void addFoodToCart(Food food, String id) {
    Provider.of<Cart>(context, listen: false).addItemToCart(food, id);
    showDialog(
      context: context,
      builder:
          (context) => const AlertDialog(
            backgroundColor: Colors.white,
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
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Pesquisar por nome ou preço',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: const Color.fromARGB(255, 196, 196, 196),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _foodStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox();
                    } else if (snapshot.hasError) {
                      return Text('Erro ao carregar categorias.');
                    } else if (snapshot.hasData) {
                      final allFoods = snapshot.data!;
                      final uniqueCategories = <String>{'Todos', 'Promoção'};
                      for (var item in allFoods) {
                        uniqueCategories.add((item['food'] as Food).category);
                      }
                      _categories = uniqueCategories.toList();

                      return SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: FilterChip(
                                label: Text(category),
                                selected: _selectedCategory == category,
                                selectedColor: Colors.amber,
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color:
                                      _selectedCategory == category
                                          ? Colors.white
                                          : Colors.amber.shade700,
                                ),
                                showCheckmark: false,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedCategory =
                                        selected ? category : 'Todos';
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      );
                    } else {
                      return const SizedBox();
                    }
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _foodStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('Erro ao carregar os produtos.'),
                      );
                    } else if (snapshot.hasData) {
                      final allFoods = snapshot.data!;
                      final filteredFoods =
                          allFoods.where((item) {
                            final food = item['food'] as Food;
                            final hasStock = food.quantity > 0;
                            final matchesCategory =
                                _selectedCategory == 'Todos' ||
                                (food.category == _selectedCategory &&
                                    _selectedCategory != 'Promoção') ||
                                (_selectedCategory == 'Promoção' &&
                                    food.isPromotional);
                            final nameMatches = food.name
                                .toLowerCase()
                                .contains(_searchQuery);
                            final priceMatches = food.price
                                .toString()
                                .toLowerCase()
                                .contains(_searchQuery);
                            return hasStock &&
                                matchesCategory &&
                                (nameMatches || priceMatches);
                          }).toList();

                      return Padding(
                        // Adicione um Padding aqui para as margens laterais
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: GridView.builder(
                          itemCount: filteredFoods.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio:
                                    0.7, // Ajuste este valor se precisar mudar a proporção
                                crossAxisSpacing: 25.0,
                                mainAxisSpacing: 25.0,
                              ),

                          itemBuilder: (context, index) {
                            final item = filteredFoods[index];
                            final food = item['food'] as Food;
                            final id = item['id'] as String;
                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return FoodDetailPopup(
                                      food: food,
                                      id: id,
                                      onAddToCart: addFoodToCart,
                                    );
                                  },
                                );
                              },
                              child: FoodTile(
                                food: food,
                                onTap: () => addFoodToCart(food, id),
                              ),
                            );
                          },
                        ),
                      );
                    } else {
                      return const Center(
                        child: Text('Nenhum produto disponível.'),
                      );
                    }
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 25, right: 25),
                child: Divider(color: Colors.white),
              ),
            ],
          ),
    );
  }
}
