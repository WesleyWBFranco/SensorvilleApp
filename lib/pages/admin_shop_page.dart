import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../models/food.dart';
import '../components/add_food_dialog.dart';
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

  bool _isCloseToExpire(DateTime? expiryDate) {
    if (expiryDate == null) {
      return false;
    }
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    return difference.inDays < 60 && difference.inDays >= 0;
  }

  Future<void> _generateStockPdfReport() async {
    final pdf = pw.Document();
    final snapshot =
        await Provider.of<Cart>(context, listen: false).foodCollection.get();

    if (snapshot.docs.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          build:
              (pw.Context context) => [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Relatório de Estoque',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Gerado no dia ${DateFormat('dd/MM/yyyy').format(DateTime.now())} ',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(120),
                    1: const pw.FixedColumnWidth(60),
                    2: const pw.FixedColumnWidth(60),
                    3: const pw.FixedColumnWidth(80),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'Nome',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Preço',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Estoque',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Validade',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    ...snapshot.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final food = Food.fromJson(data);
                      return pw.TableRow(
                        children: [
                          pw.Text(food.name ?? ''),
                          pw.Text(
                            'R\$ ${food.price?.toStringAsFixed(2) ?? '0.00'}',
                          ),
                          pw.Text('${food.quantity ?? 0}'),
                          pw.Text(
                            food.expiryDate != null
                                ? DateFormat(
                                  'dd/MM/yyyy',
                                ).format(food.expiryDate!.toLocal())
                                : 'N/A',
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
        ),
      );

      try {
        final externalDir = await getExternalStorageDirectory();
        final file = File(
          '${externalDir?.path}/relatorio_estoque_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
        );
        await file.writeAsBytes(await pdf.save());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Relatório de estoque gerado em: ${file.path}'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao gerar relatório de estoque: $e')),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum item no estoque para gerar relatório.'),
          ),
        );
      }
    }
  }

  Future<void> _generateSalesPdfReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final pdf = pw.Document();
    final startTimestamp = Timestamp.fromDate(startDate);
    final endTimestamp = Timestamp.fromDate(
      endDate.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
    ); // Inclui o dia final até o último segundo

    final ordersSnapshot =
        await Provider.of<Cart>(context, listen: false).orderCollection
            .where('data', isGreaterThanOrEqualTo: startTimestamp)
            .where('data', isLessThanOrEqualTo: endTimestamp)
            .get();

    if (ordersSnapshot.docs.isNotEmpty) {
      Map<String, int> salesData = {};
      for (var orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        final items = orderData['itens'] as List<dynamic>?;
        if (items != null) {
          for (var item in items) {
            final foodName = item['nome'] as String?;
            final quantity = item['quantidade'] as int?;
            if (foodName != null && quantity != null) {
              salesData[foodName] = (salesData[foodName] ?? 0) + quantity;
            }
          }
        }
      }

      if (salesData.isNotEmpty) {
        pdf.addPage(
          pw.MultiPage(
            build:
                (pw.Context context) => [
                  pw.Header(
                    level: 0,
                    child: pw.Text(
                      'Relatório de Vendas',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Referente ao período entre ${DateFormat('dd/MM/yyyy').format(startDate)} e ${DateFormat('dd/MM/yyyy').format(endDate)}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(150),
                      1: const pw.FixedColumnWidth(80),
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Text(
                            'Produto',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'Total Vendido',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                      ...salesData.entries.map((entry) {
                        return pw.TableRow(
                          children: [
                            pw.Text(entry.key),
                            pw.Text('${entry.value}'),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ],
          ),
        );

        try {
          final externalDir = await getExternalStorageDirectory();
          final file = File(
            '${externalDir?.path}/relatorio_vendas_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
          );
          await file.writeAsBytes(await pdf.save());
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Relatório de vendas gerado em: ${file.path}'),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao gerar relatório de vendas: $e')),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhuma venda registrada no período selecionado.'),
            ),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum pedido encontrado no período selecionado.'),
          ),
        );
      }
    }
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
                  print('Dados do Stream: ${snapshot.data}');
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
                            .contains(_searchQuery);
                        return nameMatches || priceMatches || stockMatches;
                      }).toList();

                  if (_sortByStock) {
                    filteredFoods.sort((a, b) {
                      final foodA = a['food'] as Food;
                      final foodB = b['food'] as Food;
                      return foodA.quantity.compareTo(foodB.quantity);
                    });
                  }

                  return ListView.builder(
                    itemCount: filteredFoods.length,
                    itemBuilder: (context, index) {
                      final food = filteredFoods[index]['food'] as Food;
                      final id = filteredFoods[index]['id'];
                      final referenceLevel = _referenceStockLevel[id] ?? 0;
                      final isLowStock = food.quantity <= referenceLevel;
                      final isCloseToExpire = _isCloseToExpire(food.expiryDate);

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
                            'R\$ ${food.price} | Estoque: ${food.quantity}${food.expiryDate != null ? ' | Validade: ${DateFormat('dd/MM/yyyy').format(food.expiryDate!.toLocal())}' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (food.expiryDate != null)
                                Icon(
                                  Icons.calendar_today,
                                  color:
                                      isCloseToExpire
                                          ? Colors.red
                                          : Colors.amber,
                                ),
                              const SizedBox(width: 8),
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
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 25, top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.white),
                        const Text(
                          'Item',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 8,
                ), // Adicione algum espaço entre os botões
                Expanded(
                  // ou Flexible()
                  child: ElevatedButton(
                    onPressed: _generateStockPdfReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.white),
                        const Text(
                          'Estoque',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  // ou Flexible()
                  child: ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.white),
                        const Text(
                          'Vendas',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                                ? DateFormat(
                                  'yyyy-MM-dd',
                                ).format(addedDate!.toLocal())
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
                                ? DateFormat(
                                  'yyyy-MM-dd',
                                ).format(expiryDate!.toLocal())
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
    DateTime? expiryDate,
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

  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTime? pickedStartDate = await showDatePicker(
      context: context,
      initialDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.amber,
              onPrimary: Colors.white,
              secondary: Colors.amberAccent,
              onSecondary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.amber),
            ),
          ),
          child: AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Selecione a Data de Início'),
            content: SizedBox(width: 300, height: 400, child: child),
          ),
        );
      },
    );

    if (pickedStartDate != null) {
      setState(() {
        _startDate = pickedStartDate;
      });

      final DateTime? pickedEndDate = await showDatePicker(
        context: context,
        initialDate: _endDate ?? pickedStartDate,
        firstDate: pickedStartDate,
        lastDate: DateTime.now(),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.amber,
                onPrimary: Colors.white,
                secondary: Colors.amberAccent,
                onSecondary: Colors.white,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: Colors.amber),
              ),
            ),
            child: AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Selecione a Data de Fim'),
              content: SizedBox(width: 300, height: 400, child: child),
            ),
          );
        },
      );

      if (pickedEndDate != null) {
        setState(() {
          _endDate = pickedEndDate;
        });
        _generateSalesPdfReport(_startDate!, _endDate!);
      } else {
        setState(() {
          _startDate = null;
        });
      }
    }
  }
}
