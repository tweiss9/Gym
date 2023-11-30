import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  NutritionPageState createState() => NutritionPageState();
}

class NutritionPageState extends State<NutritionPage> {
  int _currentIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Page'),
      ),
      body: const Center(
        child: Text(
            'This is the Nutrition Page content.\n This page is under construction.'),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
