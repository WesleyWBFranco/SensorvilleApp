import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sensorvilleapp/pages/feedback_form_page.dart';
import 'package:sensorvilleapp/pages/my_orders_page.dart';
import '../components/bottom_nav_bar.dart';
import 'about_page.dart';
import 'cart_page.dart';
import 'login_page.dart';
import 'shop_page.dart';
import 'admin_shop_page.dart';
import 'feedback_admin_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  final List<Widget> _pages = [
    const ShopPage(), // Índice 0 - Vendinha
    const CartPage(), // Índice 1 - Carrinho
    const AboutPage(), // Índice 2 - Sobre
    const MyOrdersPage(), // Índice 3 - Compras
    const FeedbackFormPage(), // Índice 4 - Sugestões (para usuários não admin inicialmente)
    // AdminShopPage será no índice 5 se for admin
    // FeedbackAdminPage será no índice 6 se for admin
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        if (data != null && data['role'] == 'admin') {
          setState(() {
            _isAdmin = true;
            // Adiciona ou substitui AdminShopPage no índice 5
            if (_pages.length > 5) {
              if (_pages[5] is! AdminShopPage) {
                _pages[5] = const AdminShopPage();
              }
            } else {
              _pages.add(const AdminShopPage());
            }
            // Adiciona ou substitui FeedbackAdminPage no índice 6
            if (_pages.length > 6) {
              if (_pages[6] is! FeedbackAdminPage) {
                _pages[6] = const FeedbackAdminPage();
              }
            } else {
              _pages.add(const FeedbackAdminPage());
            }
          });
        } else {
          _isAdmin = false;
          // Remove AdminShopPage se existir no índice 5
          if (_pages.length > 5 && _pages[5] is AdminShopPage) {
            _pages.removeAt(5);
          }
          // Remove FeedbackAdminPage se existir no índice 6
          if (_pages.length > 6 && _pages[6] is FeedbackAdminPage) {
            _pages.removeAt(6);
          }
        }
      } else {
        _isAdmin = false;
        if (_pages.length > 5 && _pages[5] is AdminShopPage) {
          _pages.removeAt(5);
        }
        if (_pages.length > 6 && _pages[6] is FeedbackAdminPage) {
          _pages.removeAt(6);
        }
      }
    } else {
      _isAdmin = false;
      if (_pages.length > 5 && _pages[5] is AdminShopPage) {
        _pages.removeAt(5);
      }
      if (_pages.length > 6 && _pages[6] is FeedbackAdminPage) {
        _pages.removeAt(6);
      }
    }
  }

  void navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
      if (_isAdmin) {
        if (index == 2) {
          _selectedIndex = 5;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? user =
        FirebaseAuth.instance.currentUser; // Acesse currentUser aqui

    if (user != null) {
      return Scaffold(
        backgroundColor: Colors.grey[200],
        bottomNavigationBar:
            (_selectedIndex == 0 ||
                    _selectedIndex == 1 ||
                    (_isAdmin && _selectedIndex == 5)) // Ajuste a condição aqui
                ? MyBottomNavBar(
                  onTabChange: (index) => navigateBottomBar(index),
                  isAdmin: _isAdmin,
                  selectedIndexFromParent:
                      _selectedIndex, // Passa o _selectedIndex do HomePage
                )
                : null,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Builder(
            builder:
                (context) => IconButton(
                  icon: const Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Icon(Icons.menu, color: Colors.amber),
                  ),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
          ),
        ),
        drawer: Drawer(
          backgroundColor: Colors.amber,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 25.0),
                    child: DrawerHeader(
                      child: Image.asset(
                        'lib/images/sv-logo.png',
                        color: Colors.black,
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.home,
                    title: 'Início',
                    onTap: () {
                      Navigator.pop(context);
                      navigateBottomBar(0);
                    },
                  ),

                  _buildDrawerItem(
                    icon: Icons.shopping_bag,
                    title: 'Compras',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 3);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.feedback,
                    title: 'Sugestões',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        if (_isAdmin) {
                          _selectedIndex =
                              _pages.length > 6 ? 6 : -1; // FeedbackAdminPage
                        } else {
                          _selectedIndex = 4; // FeedbackFormPage
                        }
                      });
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info,
                    title: 'Sobre',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 2);
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25.0, bottom: 25.0),
                child: GestureDetector(
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    // A reconstrução do widget ocorrerá aqui após o sign-out
                  },
                  child: const ListTile(
                    leading: Icon(Icons.logout, color: Colors.black),
                    title: Text('Sair', style: TextStyle(color: Colors.black)),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: IndexedStack(index: _selectedIndex, children: _pages),
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(showRegisterPage: () {}),
          ),
        );
      });
      return const Scaffold(
        // Adicionei const aqui
        body: Center(child: CircularProgressIndicator()),
      );
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 25.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(title, style: const TextStyle(color: Colors.black)),
        onTap: onTap,
      ),
    );
  }
}
