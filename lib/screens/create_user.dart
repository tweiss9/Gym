import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gym/screens/sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'workout.dart';
import '/widgets/show_error.dart';

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

  @override
  void initState() {
    super.initState();
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
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        labelStyle: const TextStyle(color: Colors.black),
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
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        String uid = userCredential.user!.uid;
        SharedPreferences preference = await SharedPreferences.getInstance();
        await preference.setString("uid", uid);
        await preference.setString("name", nameController.text);

        await FirebaseDatabase.instance.ref().child('users').child(uid).set({
          'Account Information': {
            'name': nameController.text,
            'email': emailController.text,
          },
          'Workouts': {}
        });

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WorkoutPage(),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        handleFirebaseAuthError(e);
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(context, "Error: $e");
        }
      }
    }
  }

  void handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        ErrorHandler.showError(
            context, 'Email is already in use. Please use a different email.');
        break;
      case 'invalid-email':
        ErrorHandler.showError(
            context, 'Invalid email address. Please enter a valid email.');
        break;
      case 'weak-password':
        ErrorHandler.showError(context,
            'Weak password. Password should be at least 6 characters long.');
        break;
      default:
        ErrorHandler.showError(context,
            'An error occurred during account creation. Please try again.');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32,
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
                const SizedBox(height: 100),
                ElevatedButton(
                  onPressed: () async {
                    performUserCreation();
                  },
                  style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      fixedSize: const Size(320, 40),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero)),
                  child: const Text("Create",
                      style: TextStyle(
                        fontSize: 20,
                      )),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      fixedSize: const Size(320, 40),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero)),
                  child: const Text("Go Back to Sign In Page",
                      style: TextStyle(
                        fontSize: 20,
                      )),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
