import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; // Importe o pacote uuid
import '../models/cart.dart';
import '../models/food.dart';

class AddFoodDialog extends StatefulWidget {
    @override
    _AddFoodDialogState createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
    final _formKey = GlobalKey<FormState>();
    String _name = '';
    double _price = 0.0;
    String _imagePath = '';
    String _description = '';
    int _quantity = 1;
    String _category = '';
    DateTime _addedDate = DateTime.now();
    DateTime _expiryDate = DateTime.now().add(Duration(days: 30));
    final ImagePicker _picker = ImagePicker();
    File? _image;

    Future getImage(ImageSource source) async {
        final pickedFile = await _picker.pickImage(source: source);

        setState(() {
            if (pickedFile != null) {
                _image = File(pickedFile.path);
                _imagePath = pickedFile.path; // Salva o caminho da imagem
            } else {
                print('Nenhuma imagem selecionada.');
            }
        });
    }

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: Text('Adicionar Item'),
            content: SingleChildScrollView(
                child: Form(
                    key: _formKey,
                    child: Column(
                        children: [
                            TextFormField(
                                decoration: InputDecoration(labelText: 'Nome'),
                                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                                onSaved: (value) => _name = value!,
                            ),
                            TextFormField(
                                decoration: InputDecoration(labelText: 'Preço'),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                                onSaved: (value) => _price = double.parse(value!.replaceAll(',', '.')),
                            ),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                    ElevatedButton(
                                        onPressed: () => getImage(ImageSource.gallery),
                                        child: Text('Galeria'),
                                    ),
                                    ElevatedButton(
                                        onPressed: () => getImage(ImageSource.camera),
                                        child: Text('Câmera'),
                                    ),
                                ],
                            ),
                            if (_image != null)
                                Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.file(_image!),
                                ),
                            TextFormField(
                                decoration: InputDecoration(labelText: 'Descrição'),
                                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                                onSaved: (value) => _description = value!,
                            ),
                            TextFormField(
                                decoration: InputDecoration(labelText: 'Quantidade'),
                                keyboardType: TextInputType.number,
                                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                                onSaved: (value) => _quantity = int.parse(value!),
                            ),
                            TextFormField(
                                decoration: InputDecoration(labelText: 'Categoria'),
                                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                                onSaved: (value) => _category = value!,
                            ),
                            ListTile(
                                title: Text('Data de Adição: ${_addedDate.toLocal()}'),
                                trailing: Icon(Icons.calendar_today),
                                onTap: () async {
                                    final DateTime? pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: _addedDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2101),
                                    );
                                    if (pickedDate != null) {
                                        final TimeOfDay? pickedTime = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.fromDateTime(_addedDate),
                                        );
                                        if (pickedTime != null) {
                                            setState(() {
                                                _addedDate = DateTime(
                                                    pickedDate.year,
                                                    pickedDate.month,
                                                    pickedDate.day,
                                                    pickedTime.hour,
                                                    pickedTime.minute,
                                                );
                                            });
                                        }
                                    }
                                },
                            ),
                            ListTile(
                                title: Text('Data de Validade: ${_expiryDate.toLocal()}'),
                                trailing: Icon(Icons.calendar_today),
                                onTap: () async {
                                    final DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: _expiryDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2101),
                                    );
                                    if (picked != null && picked != _expiryDate)
                                        setState(() {
                                            _expiryDate = picked;
                                        });
                                },
                            ),
                            ElevatedButton(
                                onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                        _formKey.currentState!.save();
                                        final uuid = const Uuid(); // Crie uma instância do Uuid
                                        final food = Food(
                                            id: uuid.v4(), // Gere um UUID e forneça-o como valor para o id
                                            name: _name,
                                            price: _price,
                                            imagePath: _imagePath,
                                            description: _description,
                                            quantity: _quantity,
                                            category: _category,
                                            addedDate: _addedDate,
                                            expiryDate: _expiryDate,
                                        );
                                        Provider.of<Cart>(
                                            context,
                                            listen: false,
                                        ).addFoodToFirestore(food);
                                        Navigator.of(context).pop();
                                    }
                                },
                                child: Text('Adicionar'),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}