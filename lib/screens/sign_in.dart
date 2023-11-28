import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'
    show DataSnapshot, DatabaseEvent, DatabaseReference, FirebaseDatabase;
import 'package:flutter/material.dart';
import 'home.dart';
import 'create_user.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleSignIn() async {
    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      try {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
      } on FirebaseAuthException catch (e) {
        switch (e.code) {
          case 'invalid-credential':
            showError('Incorrect email or password. Please try again.');
            break;
          case 'invalid-email':
            showError('Invalid email. Please enter a valid email.');
            break;
          case 'user-disabled':
            showError('User disabled. Please contact support.');
            break;
          case 'too-many-requests':
            showError('Too many requests. Please try again later.');
            break;
          default:
            showError(e.message ?? 'Unknown error occurred.');
        }
      } catch (e) {
        showError("Error: $e");
      }
    } else {
      showError('Please fill in both email and password fields.');
    }
  }

  Future<String> fetchName(String uid) async {
    try {
      DatabaseReference usersRef =
          FirebaseDatabase.instance.ref().child('users');

      DatabaseEvent event = await usersRef.child(uid).once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null && snapshot.value is Map<dynamic, dynamic>) {
        Map<dynamic, dynamic> userData =
            snapshot.value as Map<dynamic, dynamic>;

        Map<String, dynamic> typedData = Map<String, dynamic>.from(userData);

        if (typedData.containsKey('name')) {
          return typedData['name'].toString();
        } else {
          throw Exception('Name not available');
        }
      } else {
        throw Exception('Invalid data structure');
      }
    } catch (e) {
      throw Exception('Error fetching name: $e');
    }
  }

  void showError(String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await handleSignIn();
              },
              child: const Text('Sign In'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateUserPage(),
                  ),
                );
              },
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }
}
