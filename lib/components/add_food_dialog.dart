import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddFoodDialog extends StatefulWidget {
  const AddFoodDialog({super.key});

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _quantityController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _imageLinkController = TextEditingController();
  String? _previewImageUrl;
  bool _isPromotional = false;
  DateTime? _addedDate = DateTime.now();
  DateTime? _expiryDate;
  List<String> _existingCategories = [];
  List<String> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _loadExistingCategories();
    _categoryController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _categoryController.removeListener(_filterCategories);
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingCategories() async {
    print("Iniciando _loadExistingCategories"); // LOG
    final foodsSnapshot =
        await FirebaseFirestore.instance.collection('foods').get();
    Set<String> categories = {};
    for (var doc in foodsSnapshot.docs) {
      final category = doc.data()['category'] as String?;
      if (category != null && category.isNotEmpty) {
        categories.add(category.trim());
      }
    }
    setState(() {
      _existingCategories = categories.toList()..sort();
      _filteredCategories = _existingCategories;
      print(
        "_loadExistingCategories concluído. Categorias: $_existingCategories",
      ); // LOG
    });
  }

  void _filterCategories() {
    final query = _categoryController.text.toLowerCase();
    print("Iniciando _filterCategories com query: $query"); // LOG

    if (query.isEmpty) {
      setState(() {
        _filteredCategories = _existingCategories;
      });
      return;
    }

    final filtered =
        _existingCategories
            .where((category) => category.toLowerCase().startsWith(query))
            .toList();

    // Verifica se houve mudança antes de atualizar o estado
    if (!ListEquality().equals(filtered, _filteredCategories)) {
      setState(() {
        _filteredCategories = filtered;
        print(
          "_filterCategories concluído. Categorias filtradas: $_filteredCategories",
        ); // LOG
      });
    }
  }

  void _updatePreview() {
    setState(() {
      _previewImageUrl = _imageLinkController.text.trim();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isExpiry) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isExpiry
              ? _expiryDate ?? DateTime.now().add(Duration(days: 30))
              : _addedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _addedDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Adicionar Novo Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do produto.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Preço'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o preço.';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor, insira um valor numérico válido.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantidade'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a quantidade.';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor, insira um número inteiro válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Categoria'),
                readOnly: false,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: _existingCategories.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_existingCategories[index]),
                            onTap: () {
                              setState(() {
                                _categoryController.text =
                                    _existingCategories[index];
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
              const SizedBox(height: 15),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _imageLinkController,
                decoration: const InputDecoration(labelText: 'Link da Imagem'),
                onChanged: (value) {
                  _updatePreview();
                },
              ),
              const SizedBox(height: 8.0),
              if (_previewImageUrl != null && _previewImageUrl!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4.0),
                    const Text('Prévia:'),
                    SizedBox(
                      child: Image.network(
                        _previewImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Text('Erro na prévia');
                        },
                      ),
                    ),
                    const SizedBox(height: 8.0),
                  ],
                ),
              const SizedBox(height: 15),
              DropdownButtonFormField<bool>(
                decoration: const InputDecoration(labelText: 'Promocional'),
                value: _isPromotional,
                items: const [
                  DropdownMenuItem(
                    value: true,
                    child: Text(
                      'Sim',
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text(
                      'Não',
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ),
                ],
                onChanged: (bool? newValue) {
                  setState(() {
                    _isPromotional = newValue ?? false;
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
                        _addedDate != null
                            ? DateFormat('yyyy-MM-dd').format(_addedDate!)
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
                        _expiryDate != null
                            ? DateFormat('yyyy-MM-dd').format(_expiryDate!)
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
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar', style: TextStyle(color: Colors.amber)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text,
                'price': double.tryParse(_priceController.text) ?? 0.0,
                'quantity': int.tryParse(_quantityController.text) ?? 0,
                'category': _categoryController.text,
                'description': _descriptionController.text,
                'isPromotional': _isPromotional,
                'addedDate': _addedDate,
                'expiryDate': _expiryDate,
                'imagePath': _imageLinkController.text,
              });
            }
          },
          child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
