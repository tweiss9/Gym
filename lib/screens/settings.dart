import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart'
    show DataSnapshot, DatabaseEvent, DatabaseReference, FirebaseDatabase;
import '/widgets/bottom_navigation.dart';
import 'sign_in.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final GlobalKey<ScaffoldState> scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 4;
  final FirebaseAuth auth = FirebaseAuth.instance;

  late Future<String?> userNameFuture;

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
      showError("Error signing out: $e");
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
                } else if (snapshot.hasError || snapshot.data == null) {
                  return const Text('Error: Empty data!');
                } else {
                  return Text('Hello, ${snapshot.data}!');
                }
              },
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
