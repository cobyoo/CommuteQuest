import 'package:flutter/material.dart';

import 'shop_screen.dart';
import 'inventory_screen.dart';

class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('장비'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.store), text: '상점'),
              Tab(icon: Icon(Icons.inventory_2), text: '인벤토리'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ShopScreen(),
            InventoryScreen(),
          ],
        ),
      ),
    );
  }
}
