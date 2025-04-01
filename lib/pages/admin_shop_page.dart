import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../models/food.dart';
import '../components/add_food_dialog.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class AdminShopPage extends StatefulWidget {
  const AdminShopPage({super.key});

  @override
  State<AdminShopPage> createState() => _AdminShopPageState();
}

class _AdminShopPageState extends State<AdminShopPage> {
  String _searchQuery = '';
  List<String> _existingCategories = [];
  List<String> _filteredCategories = [];
  Stream<List<Map<String, dynamic>>>? _foodStream;
  Map<String, int> _referenceStockLevel = {};
  bool _sortByStock = true;

  @override
  void initState() {
    super.initState();
    _foodStream =
        Provider.of<Cart>(context, listen: false).getFoodListAsStream();
    _loadExistingCategories();
    _loadReferenceStockLevels();
  }

  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();

    final snapshot =
        await _foodStream?.first; // Obtém o primeiro valor da stream

    if (snapshot != null && snapshot.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          build:
              (pw.Context context) => [
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(150),
                    1: const pw.FixedColumnWidth(80),
                    2: const pw.FixedColumnWidth(80),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'Nome',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Valor',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Estoque',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    for (var item in snapshot)
                      pw.TableRow(
                        children: [
                          pw.Text((item['food'] as Food).name),
                          pw.Text(
                            'R\$ ${(item['food'] as Food).price.toStringAsFixed(2)}',
                          ),
                          pw.Text('${(item['food'] as Food).quantity}'),
                        ],
                      ),
                  ],
                ),
              ],
        ),
      );

      // Salvar o PDF
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/relatorio_estoque.pdf');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Relatório PDF gerado em: ${file.path}')),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum item para gerar relatório.')),
        );
      }
    }
  }

  Future<void> _loadReferenceStockLevels() async {
    final foodsSnapshot =
        await Provider.of<Cart>(context, listen: false).foodCollection.get();
    Map<String, int> levels = {};
    for (var doc in foodsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('referenceStockLevel')) {
        levels[doc.id] = data['referenceStockLevel'] as int? ?? 0;
      } else {
        levels[doc.id] = 0; // Define o valor padrão como 0 se não existir
        // Atualizar o documento no Firestore com o valor padrão
        Provider.of<Cart>(
          context,
          listen: false,
        ).foodCollection.doc(doc.id).update({'referenceStockLevel': 0});
      }
    }
    setState(() {
      _referenceStockLevel = levels;
    });
  }

  Future<void> _updateReferenceStockLevel(String foodId, int newLevel) async {
    setState(() {
      _referenceStockLevel[foodId] = newLevel;
    });
    await Provider.of<Cart>(
      context,
      listen: false,
    ).foodCollection.doc(foodId).update({'referenceStockLevel': newLevel});
  }

  Future<void> _showSetReferenceLevelDialog(
    BuildContext context,
    Food food,
    String foodId,
  ) async {
    TextEditingController controller = TextEditingController(
      text: _referenceStockLevel[foodId]?.toString() ?? '0',
    );
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Definir alerta de Estoque para ${food.name}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Quantidade Mínima'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: Colors.amber)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: Text('Salvar', style: TextStyle(color: Colors.white)),
              onPressed: () {
                final newLevel = int.tryParse(controller.text) ?? 0;
                _updateReferenceStockLevel(foodId, newLevel);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadExistingCategories() async {
    final foodsSnapshot =
        await Provider.of<Cart>(context, listen: false).foodCollection.get();
    Set<String> categories = {};
    for (var doc in foodsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('category')) {
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category.trim());
        }
      }
    }
    setState(() {
      _existingCategories = categories.toList()..sort();
      _filteredCategories = _existingCategories;
    });
  }

  void _filterCategories(String query) {
    final lowerCaseQuery = query.toLowerCase();
    setState(() {
      _filteredCategories =
          _existingCategories
              .where((cat) => cat.toLowerCase().startsWith(lowerCaseQuery))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome, preço ou estoque',
                hintStyle: TextStyle(color: Colors.grey[400]),
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
          const Padding(
            padding: EdgeInsets.only(top: 10, left: 25, right: 25),
            child: Divider(color: Colors.white),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _foodStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final filteredFoods =
                      snapshot.data!.where((item) {
                        final food = item['food'] as Food;
                        final nameMatches = food.name.toLowerCase().contains(
                          _searchQuery,
                        );
                        final priceMatches = food.price
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery);
                        final stockMatches = food.quantity
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery); // Nova condição
                        return nameMatches ||
                            priceMatches ||
                            stockMatches; // Inclui a nova condição
                      }).toList();

                  if (_sortByStock) {
                    filteredFoods.sort((a, b) {
                      final foodA = a['food'] as Food;
                      final foodB = b['food'] as Food;
                      return foodA.quantity.compareTo(foodB.quantity);
                    });
                  }

                  for (var item in snapshot.data!) {
                    final food = item['food'] as Food;
                    final id = item['id'];
                    final referenceLevel = _referenceStockLevel[id] ?? 0;
                  }
                  return ListView.builder(
                    itemCount: filteredFoods.length,
                    itemBuilder: (context, index) {
                      final food = filteredFoods[index]['food'] as Food;
                      final id = filteredFoods[index]['id'];
                      final referenceLevel = _referenceStockLevel[id] ?? 0;
                      final isLowStock = food.quantity <= referenceLevel;
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(
                            food.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'R\$ ${food.price} | Estoque: ${food.quantity}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.notifications),
                                color: isLowStock ? Colors.red : Colors.amber,
                                onPressed:
                                    () => _showSetReferenceLevelDialog(
                                      context,
                                      food,
                                      id,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.amber,
                                ),
                                onPressed: () {
                                  _showEditDialog(context, food, id);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.amber,
                                ),
                                onPressed: () {
                                  _deleteFood(context, id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(child: Text('Nenhum dado disponível.'));
                }
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10, left: 25, right: 25),
            child: Divider(color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddFoodDialog(),
              ).then((newItem) {
                if (newItem != null) {
                  _addNewFood(newItem);
                }
              });
            },
            backgroundColor: Colors.amber,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _generatePdfReport, // Função a ser implementada
            backgroundColor: Colors.amber,
            child: const Icon(Icons.document_scanner, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Food food, String id) {
    TextEditingController nameController = TextEditingController(
      text: food.name,
    );
    TextEditingController priceController = TextEditingController(
      text: food.price.toString(),
    );
    TextEditingController quantityController = TextEditingController(
      text: food.quantity.toString(),
    );
    TextEditingController categoryController = TextEditingController(
      text: food.category,
    );
    TextEditingController descriptionController = TextEditingController(
      text: food.description,
    );
    bool isPromotional = food.isPromotional;
    DateTime? addedDate = food.addedDate;
    DateTime? expiryDate = food.expiryDate;
    String? imagePath = food.imagePath;
    String? newImagePath;

    categoryController.addListener(() {
      _filterCategories(categoryController.text);
    });

    Future<void> _selectDate(BuildContext context, bool isExpiry) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate:
            isExpiry
                ? expiryDate ?? DateTime.now().add(const Duration(days: 30))
                : addedDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        setState(() {
          if (isExpiry) {
            expiryDate = picked;
          } else {
            addedDate = picked;
          }
        });
      }
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Editar Produto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Preço'),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Quantidade'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    readOnly: false,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredCategories.length,
                            itemBuilder: (context, index) {
                              final category = _filteredCategories[index];
                              return ListTile(
                                title: Text(category),
                                onTap: () {
                                  setState(() {
                                    categoryController.text = category;
                                    Navigator.pop(context);
                                  });
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Novo Link da Imagem (Opcional)',
                    ),
                    onChanged: (value) {
                      newImagePath = value.isNotEmpty ? value : null;
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Imagem Atual',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  if (imagePath != null && imagePath.isNotEmpty)
                    if (imagePath!.startsWith('/') ||
                        imagePath!.startsWith('file://'))
                      FutureBuilder<bool>(
                        future: File(imagePath!).exists(),
                        builder: (
                          BuildContext context,
                          AsyncSnapshot<bool> snapshot,
                        ) {
                          if (snapshot.data == true) {
                            return Center(
                              child: Image.file(
                                File(imagePath!),
                                fit: BoxFit.cover,
                              ),
                            );
                          } else {
                            return const Text(
                              'Arquivo de imagem não encontrado',
                            );
                          }
                        },
                      )
                    else
                      Center(
                        child: Image.network(
                          imagePath!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text(
                              'Erro ao carregar imagem da rede',
                            );
                          },
                        ),
                      )
                  else
                    const Text('Sem imagem disponível'),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<bool>(
                    decoration: const InputDecoration(labelText: 'Promocional'),
                    value: isPromotional,
                    items:
                        <bool>[true, false].map((bool value) {
                          return DropdownMenuItem<bool>(
                            value: value,
                            child: Text(
                              value ? 'Sim' : 'Não',
                              style: TextStyle(fontWeight: FontWeight.normal),
                            ),
                          );
                        }).toList(),
                    onChanged: (bool? newValue) {
                      setState(() {
                        isPromotional = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Selecionar Data de Adição',
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            addedDate != null
                                ? DateFormat('yyyy-MM-dd').format(
                                  addedDate!.toLocal(),
                                ) // Adicionada verificação de nulo (!)
                                : 'Não selecionada',
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Selecionar Data de Validade (Opcional)',
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            expiryDate != null
                                ? DateFormat('yyyy-MM-dd').format(
                                  expiryDate!.toLocal(),
                                ) // Adicionada verificação de nulo (!)
                                : 'Não selecionada',
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.amber),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () {
                  _updateFood(
                    context,
                    id,
                    nameController.text,
                    double.parse(priceController.text),
                    int.parse(quantityController.text),
                    isPromotional,
                    categoryController.text,
                    descriptionController.text,
                    newImagePath ?? imagePath,
                    addedDate: addedDate,
                    expiryDate: expiryDate,
                  );
                  Navigator.pop(context);
                },
                child: const Text(
                  'Salvar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _addNewFood(Map<String, dynamic> foodData) async {
    final cart = Provider.of<Cart>(context, listen: false);
    try {
      final newFood = Food(
        name: foodData['name'],
        price: foodData['price'],
        quantity: foodData['quantity'],
        isPromotional: foodData['isPromotional'] ?? false,
        category: foodData['category'] ?? '',
        description: foodData['description'] ?? '',
        addedDate: foodData['addedDate'] as DateTime?,
        expiryDate: foodData['expiryDate'] as DateTime?,
        imagePath: foodData['imagePath'],
      );
      await cart.addFood(newFood);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${foodData['name']} adicionado com sucesso!'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar ${foodData['name']}: $error'),
          ),
        );
      }
    }
  }

  void _updateFood(
    BuildContext context,
    String id,
    String newName,
    double newPrice,
    int newQuantity,
    bool isPromotional,
    String newCategory,
    String newDescription,
    String? newImagePath, {
    DateTime? addedDate,
    DateTime? expiryDate, // Adicionar parâmetros opcionais para as datas
  }) async {
    try {
      final cart = Provider.of<Cart>(context, listen: false);
      final foodDocRef = cart.foodCollection.doc(id);

      await foodDocRef.update({
        'name': newName,
        'price': newPrice,
        'quantity': newQuantity,
        'isPromotional': isPromotional,
        'category': newCategory,
        'description': newDescription,
        'imagePath': newImagePath,
        'addedDate': addedDate,
        'expiryDate': expiryDate,
      });

      cart.clearCart();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto atualizado! Carrinho limpo.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao atualizar: $error')));
      }
    }
  }

  void _deleteFood(BuildContext context, String id) {
    final foodDocRef = Provider.of<Cart>(
      context,
      listen: false,
    ).foodCollection.doc(id);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Excluir Produto'),
            content: const Text(
              'Tem certeza que deseja excluir este produto? Essa ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.amber),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () {
                  foodDocRef
                      .delete()
                      .then((_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Produto excluído com sucesso!'),
                            ),
                          );
                        }
                      })
                      .catchError((error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao excluir: $error')),
                          );
                        }
                      });
                  Navigator.pop(context);
                },
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
