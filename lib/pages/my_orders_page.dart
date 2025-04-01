import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _historicoCompleto = false;
  List<Map<String, dynamic>> _pedidos = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _dataInicioSelecionada = false;
  String? _selectedAdminUserId;
  List<Map<String, dynamic>> _users = [];
  bool _isAdmin = false;

  final DateFormat _formatter = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    final now = DateTime.now();
    _dataInicio = DateTime(now.year, now.month, now.day, 0, 0, 0);
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userDoc.exists && userDoc.data()?['role'] == 'admin') {
        setState(() {
          _isAdmin = true;
        });
        _loadUsers();
      } else {
        _carregarPedidos(); // Carrega os próprios pedidos se não for admin
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _users = [];
    });
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Usuário não logado.';
      });
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        _users =
            snapshot.docs
                .where(
                  (doc) => doc.id != currentUser.uid,
                ) // Filtra para excluir o usuário logado
                .map(
                  (doc) => {
                    'uid': doc.id,
                    'email': doc.data()['email'],
                    'firstName': doc.data()['first name'],
                    'lastName': doc.data()['last name'],
                    'displayName':
                        '${doc.data()['first name'] ?? ''} ${doc.data()['last name'] ?? ''}'
                            .trim(),
                  },
                )
                .toList();
        _isLoading = false;
        _carregarPedidos();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar usuários: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selecionarDataInicio(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dataInicio) {
      setState(() {
        _dataInicio = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        _dataInicioSelecionada = true;
        _dataFim = null;
        _historicoCompleto = false;
        _carregarPedidos();
      });
    }
  }

  Future<void> _selecionarDataFim(BuildContext context) async {
    if (!_dataInicioSelecionada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a Data Inicial primeiro.')),
      );
      return;
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataFim ?? _dataInicio ?? DateTime.now(),
      firstDate: _dataInicio ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dataFim) {
      setState(() {
        _dataFim = picked;
        _historicoCompleto = false;
        _carregarPedidos();
      });
    }
  }

  void _alternarHistoricoCompleto(bool? value) {
    setState(() {
      _historicoCompleto = value ?? false;
      final now = DateTime.now();
      _dataInicio =
          _historicoCompleto
              ? null
              : DateTime(now.year, now.month, now.day, 0, 0, 0);
      _dataFim = null;
      _dataInicioSelecionada = false;
      _selectedAdminUserId = null;
      _carregarPedidos();
    });
  }

  Future<void> _carregarPedidos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _pedidos = [];
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Usuário não logado.';
      });
      return;
    }

    String userIdToQuery = user.uid;
    if (_isAdmin && _selectedAdminUserId != null) {
      userIdToQuery = _selectedAdminUserId!;
    }

    Query<Map<String, dynamic>> pedidosQuery = FirebaseFirestore.instance
        .collection('pedidos')
        .where('userId', isEqualTo: userIdToQuery)
        .orderBy('data', descending: true);

    if (!_historicoCompleto) {
      if (_dataInicio != null) {
        DateTime inicioDoDiaLocal = _dataInicio!;
        DateTime inicioDoDiaUTC = inicioDoDiaLocal.toUtc();

        pedidosQuery = pedidosQuery.where(
          'data',
          isGreaterThanOrEqualTo: inicioDoDiaUTC,
        );
        if (_dataFim != null) {
          DateTime fimDoDiaLocal = _dataFim!;
          DateTime fimDoDiaUTC =
              DateTime(
                fimDoDiaLocal.year,
                fimDoDiaLocal.month,
                fimDoDiaLocal.day,
                23,
                59,
                59,
              ).toUtc();
          pedidosQuery = pedidosQuery.where(
            'data',
            isLessThanOrEqualTo: fimDoDiaUTC,
          );
        }
      }
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await pedidosQuery.get();
      _pedidos = snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar os pedidos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPedidos = _pedidos.length;
    double valorTotalGasto = _pedidos.fold(
      0,
      (sum, pedido) => sum + (pedido['total'] as num? ?? 0),
    );

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visão Geral',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Total de Compras: $totalPedidos'),
            Text(
              'Valor Total Gasto: R\$ ${valorTotalGasto.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 24),
            Text(
              'Filtrar Usuário',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_isAdmin)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Selecionar Usuário',
                        labelStyle: TextStyle(
                          color: Color.fromARGB(255, 98, 98, 98),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 110, 110, 110),
                          ),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      dropdownColor: Colors.white,
                      value: _selectedAdminUserId,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            'Ver meus pedidos',
                            style: TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ),
                        ..._users.map(
                          (user) => DropdownMenuItem<String>(
                            value: user['uid'],
                            child: Text(
                              user['displayName'].isNotEmpty
                                  ? user['displayName']
                                  : user['email'] ?? 'Usuário sem nome',
                              style: TextStyle(fontWeight: FontWeight.normal),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedAdminUserId = newValue;
                          _carregarPedidos();
                        });
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selecionarDataInicio(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data Inicial (Obrigatória)',
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      child: Text(
                        _dataInicio != null
                            ? _formatter.format(_dataInicio!)
                            : 'Selecione a data',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap:
                        _dataInicioSelecionada
                            ? () => _selecionarDataFim(context)
                            : null,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Data Final (Opcional)',
                        border: const OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                        labelStyle: TextStyle(
                          color: _dataInicioSelecionada ? null : Colors.grey,
                        ),
                      ),
                      child: Text(
                        _dataFim != null
                            ? _formatter.format(_dataFim!)
                            : 'Opcional',
                        style: TextStyle(
                          color: _dataInicioSelecionada ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _historicoCompleto,
                  onChanged: _alternarHistoricoCompleto,
                  activeColor: Colors.amber,
                ),
                const Text('Mostrar Histórico Completo'),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Lista de Compras',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage.isNotEmpty)
              Center(
                child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
              )
            else if (_pedidos.isEmpty)
              const Center(
                child: Text(
                  'Nenhuma compra encontrada para o filtro selecionado.',
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pedidos.length,
                itemBuilder: (context, index) {
                  final pedido = _pedidos[index];
                  final location = tz.getLocation('America/Sao_Paulo');
                  final localTime = tz.TZDateTime.from(
                    pedido['data'].toDate(),
                    location,
                  );
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Compra',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text('Data: ${_formatter.format(localTime)}'),
                          Text(
                            'Total: R\$ ${(pedido['total'] as num).toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Itens:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                (pedido['itens'] as List<dynamic>).map((item) {
                                  return Text(
                                    '- ${item['nome']} x ${item['quantidade']} (R\$ ${item['preco'].toStringAsFixed(2)} cada)',
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
