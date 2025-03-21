import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MyBottomNavBar extends StatelessWidget {
  void Function(int)? onTabChange;
  bool isAdmin; // Adiciona a variável isAdmin

  MyBottomNavBar({
    super.key,
    required this.onTabChange,
    this.isAdmin = false,
  }); // Atualiza o construtor

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: GNav(
        color: Colors.amber[100],
        activeColor: Colors.amber.shade700,
        tabActiveBorder: Border.all(color: Colors.white),
        tabBackgroundColor: Colors.amber.shade100,
        mainAxisAlignment: MainAxisAlignment.center,
        tabBorderRadius: 16,
        gap: 8,
        onTabChange: (value) => onTabChange!(value),
        tabs: [
          GButton(icon: Icons.home, text: 'Shop'),
          GButton(icon: Icons.shopping_bag_rounded, text: 'Cart'),
          if (isAdmin) // Verifica a variável isAdmin
            GButton(icon: Icons.add, text: 'Gerenciar'),
        ],
      ),
    );
  }
}
