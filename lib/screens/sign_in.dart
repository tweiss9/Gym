import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:flutter/material.dart';
import 'workout.dart';
import 'create_user.dart';
import '/widgets/show_error.dart';

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
    if (emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        mounted) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        User? user = FirebaseAuth.instance.currentUser;
        String uid = user!.uid;
        DatabaseReference nameRef = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(uid)
            .child('Account Information')
            .child('name');
        DatabaseEvent event = await nameRef.once();
        DataSnapshot snapshot = event.snapshot;
        String name = snapshot.value?.toString() ?? '';

        SharedPreferences preference = await SharedPreferences.getInstance();
        await preference.setString("uid", uid);
        await preference.setString("name", name);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const WorkoutPage(),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          switch (e.code) {
            case 'invalid-credential':
              ErrorHandler.showError(
                  context, 'Incorrect email or password. Please try again.');
              break;
            case 'invalid-email':
              ErrorHandler.showError(
                  context, 'Invalid email. Please enter a valid email.');
              break;
            case 'user-disabled':
              ErrorHandler.showError(
                  context, 'User disabled. Please contact support.');
              break;
            case 'too-many-requests':
              ErrorHandler.showError(
                  context, 'Too many requests. Please try again later.');
              break;
            default:
              ErrorHandler.showError(
                  context, e.message ?? 'Unknown error occurred.');
          }
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(context, "Error: $e");
        }
      }
    } else {
      ErrorHandler.showError(
          context, 'Please fill in both email and password fields.');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        if (mounted) {
          ErrorHandler.showError(context, "Signing in cancelled.");
        }
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = userCredential.user;
      String uid = user!.uid;
      SharedPreferences preference = await SharedPreferences.getInstance();
      await preference.setString("uid", uid);
      await preference.setString("name", user.displayName!);
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref().child('users').child(uid);
      DatabaseEvent snapshot = await userRef.once();
      if (snapshot.snapshot.value == null) {
        await userRef.set({
          'Account Information': {
            'name': user.displayName,
            'email': user.email
          },
          'Workouts': {}
        });
      }
      return userCredential;
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Error signing in with Google: $e');
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  labelStyle: TextStyle(color: Colors.black),
                ),
                cursorColor: Colors.black,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  labelStyle: TextStyle(color: Colors.black),
                ),
                cursorColor: Colors.black,
              ),
              const SizedBox(height: 125),
              ElevatedButton(
                onPressed: () async {
                  await handleSignIn();
                },
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    fixedSize: const Size(320, 40),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero)),
                child: const Text('Sign In',
                    style: TextStyle(
                      fontSize: 20,
                    )),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateUserPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    fixedSize: const Size(320, 40),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero)),
                child: const Text('Create User',
                    style: TextStyle(
                      fontSize: 20,
                    )),
              ),
              const SizedBox(height: 30),
              SignInButton(
                Buttons.googleDark,
                onPressed: () async {
                  final UserCredential? userCredential =
                      await signInWithGoogle();
                  if (userCredential != null) {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WorkoutPage(),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
