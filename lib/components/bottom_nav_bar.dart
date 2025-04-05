import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MyBottomNavBar extends StatefulWidget {
  final void Function(int)? onTabChange;
  final bool isAdmin;
  final int selectedIndexFromParent; 

  const MyBottomNavBar({
    Key? key,
    required this.onTabChange,
    this.isAdmin = false,
    required this.selectedIndexFromParent,
  }) : super(key: key);

  @override
  State<MyBottomNavBar> createState() => _MyBottomNavBarState();
}

class _MyBottomNavBarState extends State<MyBottomNavBar> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateCurrentIndex(widget.selectedIndexFromParent);
  }

  @override
  void didUpdateWidget(covariant MyBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndexFromParent != oldWidget.selectedIndexFromParent) {
      _updateCurrentIndex(widget.selectedIndexFromParent);
    }
  }

  void _updateCurrentIndex(int parentIndex) {
    if (widget.isAdmin) {
      if (parentIndex == 5) {
     
        _currentIndex = 2; // Índice de "Gerenciar" no GNav para admin
      } else if (parentIndex == 0) {
        _currentIndex = 0; // Vendinha
      } else if (parentIndex == 1) {
        _currentIndex = 1; // Carrinho
      } else {
        _currentIndex = -1; 
      }
    } else {
      if (parentIndex == 0) {
        _currentIndex = 0; // Vendinha
      } else if (parentIndex == 1) {
        _currentIndex = 1; // Carrinho
      } else if (parentIndex == 2) {
        _currentIndex = 2; // Sobre
      } else if (parentIndex == 3) {
        _currentIndex = 3; // Compras
      } else if (parentIndex == 4) {
        _currentIndex = 4; // Sugestões
      } else {
        _currentIndex = -1; 
      }
    }

    
    if (_currentIndex >= (widget.isAdmin ? 3 : 2)) {
      _currentIndex =
          -1; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: GNav(
        selectedIndex:
            _currentIndex, 
        color: Colors.amber[200],
        activeColor: Colors.amber.shade700,
        tabActiveBorder: Border.all(color: Colors.white),
        tabBackgroundColor: Colors.amber.shade100,
        mainAxisAlignment: MainAxisAlignment.center,
        tabBorderRadius: 16,
        gap: 8,
        onTabChange: (value) {
          setState(() {
            _currentIndex = value;
          });
          
          int translatedIndex = value;
          if (widget.isAdmin) {
            if (value == 2) {
              translatedIndex = 5; // "Gerenciar" corresponds to index 5
            } else if (value == 0) {
              translatedIndex = 0; // "Vendinha"
            } else if (value == 1) {
              translatedIndex = 1; // "Carrinho"
            }
          } else {
            if (value == 0)
              translatedIndex = 0;
            else if (value == 1)
              translatedIndex = 1;
            // Add other mappings for non-admin users if needed based on your tabs
          }
          if (widget.onTabChange != null) {
            widget.onTabChange!(translatedIndex);
          }
        },
        tabs: [
          const GButton(icon: Icons.store_mall_directory, text: 'Vendinha'),
          const GButton(icon: Icons.shopping_cart, text: 'Carrinho'),
          if (widget.isAdmin)
            const GButton(icon: Icons.settings, text: 'Gerenciar'),
        ],
      ),
    );
  }
}
