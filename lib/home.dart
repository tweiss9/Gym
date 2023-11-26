import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'sign_in.dart';

class HomePage extends StatelessWidget {
  final String name;
  final GlobalKey<ScaffoldState> scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NavigatorState> navigatorGlobalKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<State> errorGlobalKey = GlobalKey<State>();

  HomePage({super.key, required this.name});

  Future<void> signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      Navigator.of(scaffoldGlobalKey.currentContext!).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInPage()),
        (route) => false,
      );
    } catch (e) {
      showError(errorGlobalKey.currentContext, "Error signing out: $e");
    }
  }

  void showError(BuildContext? context, String message) {
    if (context != null) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldGlobalKey,
      appBar: AppBar(
        title: const Text('Home Page'),
        automaticallyImplyLeading: false,
      ),
      body: Navigator(
        key: navigatorGlobalKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Hello $name!'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => signOut(context),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
