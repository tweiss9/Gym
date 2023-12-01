import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart'
    show DataSnapshot, DatabaseEvent, DatabaseReference, FirebaseDatabase;
import 'package:google_sign_in/google_sign_in.dart';
import '/widgets/bottom_navigation.dart';
import '/widgets/show_error.dart';
import 'sign_in.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final GlobalKey<ScaffoldState> scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth auth = FirebaseAuth.instance;
  late Future<String?> userNameFuture;
  int _currentIndex = 4;

  @override
  void initState() {
    super.initState();
    userNameFuture = fetchName();
  }

  Future<String> fetchName() async {
    try {
      DatabaseReference usersRef =
          FirebaseDatabase.instance.ref().child('users');
      String uid = auth.currentUser!.uid;
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

  Future<void> editName() async {
    String? currentName = await fetchName();
    String? newName;

    if (mounted) {
      newName = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Edit Name'),
            content: TextField(
              decoration: const InputDecoration(labelText: 'New Name'),
              onChanged: (value) {
                newName = value;
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(newName);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (newName != null && newName != currentName) {
        String uid = auth.currentUser!.uid;
        String? updatedName = newName;

        await FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(uid)
            .update({'name': updatedName});

        setState(() {
          userNameFuture = Future.value(updatedName);
        });
      }
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        if (mounted) {
          ErrorHandler.showError(context, "Signing in cancelled.");
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        if (userCredential.additionalUserInfo!.isNewUser) {
          setState(() {
            userNameFuture = fetchName();
          });
        } else {
          if (mounted) {
            ErrorHandler.showError(
              context,
              "User already exists with Google email:",
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Error signing in with Google: $e');
      }
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SignInPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, "Error signing out: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldGlobalKey,
      appBar: AppBar(
        title: const Text('Settings Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder<String?>(
              future: fetchName(),
              initialData: null,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else {
                  return Text('Hello, ${snapshot.data}!');
                }
              },
            ),
            ElevatedButton(
              onPressed: editName,
              child: const Text('Edit Name'),
            ),
            ElevatedButton(
              onPressed: signInWithGoogle,
              child: const Text('Sign In with Google'),
            ),
            ElevatedButton(
              onPressed: signOut,
              child: const Text('Sign Out'),
            ),
          ],
        ),
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
