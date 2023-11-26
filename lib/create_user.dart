import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'home.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  CreateUserPageState createState() => CreateUserPageState();
}

class CreateUserPageState extends State<CreateUserPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  Map<String, String> errors = {};

  static const String _usersNode = 'users';
  final DatabaseReference _usersRef =
      FirebaseDatabase.instance.ref().child(_usersNode);

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  TextFormField buildFormField(
      String label, TextEditingController controller, String errorKey,
      {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorText: errors[errorKey],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        if (label == 'Email' &&
            !RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
                .hasMatch(value)) {
          return 'Enter a valid email address';
        }
        if (label == 'Name' && value.length < 3) {
          return 'Enter a valid name';
        }
        if (label == 'Confirm Password' && value != passwordController.text) {
          return 'Password and Confirm Password do not match';
        }
        return null;
      },
    );
  }

  Future<void> performUserCreation() async {
    if (_formKey.currentState!.validate()) {
      final BuildContext context = this.context;
      final completer = Completer<void>();

      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        String uid = userCredential.user!.uid;

        await _usersRef.child(uid).set({
          'name': nameController.text,
          'email': emailController.text,
        });

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(name: nameController.text),
            ),
          ).then((_) {
            completer.complete();
          });
        }
      } on FirebaseAuthException catch (e) {
        handleFirebaseAuthError(e);
      } catch (e) {
        completer.completeError(e);
      }

      return completer.future;
    }
  }

  bool validateInputs() {
    if (_formKey.currentState!.validate()) {
      return true;
    }
    return false;
  }

  Future<void> handleUserCreation() async {
    final completer = Completer<void>();
    final BuildContext context = this.context;

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      String uid = userCredential.user!.uid;

      await _usersRef.child(uid).set({
        'name': nameController.text,
        'email': emailController.text,
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(name: nameController.text),
          ),
        ).then((_) {
          completer.complete();
        });
      }
    } on FirebaseAuthException catch (e) {
      handleFirebaseAuthError(e);
    } catch (e) {
      completer.completeError(e);
    }

    return completer.future;
  }

  void handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        showError('Email is already in use. Please use a different email.');
        break;
      case 'invalid-email':
        showError('Invalid email address. Please enter a valid email.');
        break;
      case 'weak-password':
        showError(
            'Weak password. Password should be at least 6 characters long.');
        break;
      default:
        showError(
            'An error occurred during account creation. Please try again.');
        break;
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
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32.0),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                buildFormField('Name', nameController, 'name'),
                const SizedBox(height: 10),
                buildFormField('Email', emailController, 'email'),
                const SizedBox(height: 10),
                buildFormField('Password', passwordController, 'password',
                    isPassword: true),
                const SizedBox(height: 10),
                buildFormField('Confirm Password', confirmPasswordController,
                    'confirmPassword',
                    isPassword: true),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    performUserCreation();
                  },
                  child: const Text("Create"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
