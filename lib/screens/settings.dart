import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart'
    show DataSnapshot, DatabaseEvent, DatabaseReference, FirebaseDatabase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gym/widgets/popup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/widgets/bottom_navigation.dart';
import '/widgets/show_error.dart';
import 'sign_in.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late Future<String?> userNameFuture;
  String uid = '';
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    initializeUid();
    userNameFuture = fetchName(uid);
  }

  Future<void> initializeUid() async {
    String uidValue = await getUid();
    setState(() {
      uid = uidValue;
    });
  }

  Future<String> getUid() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString('uid') ?? '';
  }

  Future<String> fetchName(String uid) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String name = preferences.getString('name') ?? '';

    if (name.isNotEmpty) {
      return name;
    }

    try {
      if (uid.isNotEmpty) {
        DatabaseReference usersRef = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(uid)
            .child('Account Information')
            .child('name');

        DatabaseEvent event = await usersRef.once();
        DataSnapshot snapshot = event.snapshot;

        return snapshot.value?.toString() ?? '';
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Error fetching name: $e');
      }
    }
    return '';
  }

  Future<void> editName(String uid, String newName) async {
    try {
      DatabaseReference usersRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(uid)
          .child('Account Information')
          .child('name');

      await usersRef.set(newName);
      SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.setString('name', newName);
      setState(() {
        userNameFuture = fetchName(uid);
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Error editing name: $e');
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
            userNameFuture = fetchName(uid);
          });
        } else {
          if (mounted) {
            ErrorHandler.showError(
              context,
              "Google Account Already Linked",
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
    await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(uid)
        .child('Current Workout')
        .remove();
    try {
      await FirebaseAuth.instance.signOut();
      SharedPreferences preference = await SharedPreferences.getInstance();
      preference.setString('uid', '');
      preference.setString('name', '');
      preference.setBool('isWorkoutActive', false);
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

  Future<void> deleteAccount(String uid) async {
    try {
      DatabaseReference usersRef =
          FirebaseDatabase.instance.ref().child('users').child(uid);

      await usersRef.remove();
      SharedPreferences preference = await SharedPreferences.getInstance();
      preference.setString('uid', '');
      preference.setString('name', '');
      preference.setBool('isWorkoutActive', false);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SignInPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, "Error deleting account: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Settings')),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder<String?>(
              future: userNameFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasData && snapshot.data != null) {
                  return Text('Hello, ${snapshot.data}!');
                } else {
                  return const SizedBox();
                }
              },
            ),
            ElevatedButton(
              onPressed: () async {
                Popup(
                  false,
                  true,
                  title: 'Edit Name',
                  contentController: 'Edit your name below',
                  onOkPressed: ({
                    String? textInput,
                  }) {
                    editName(uid, textInput!);
                  },
                  okButtonText: 'Edit',
                  cancelButtonText: 'Cancel',
                ).show(context);
              },
              child: const Text('Edit Name'),
            ),
            ElevatedButton(
              onPressed: signInWithGoogle,
              child: const Text('Sign In with Google'),
            ),
            ElevatedButton(
              onPressed: () async {
                Popup(
                  false,
                  false,
                  title: 'Sign Out',
                  contentController:
                      'Are you sure you want to sign out? All unsaved data will be lost.',
                  onOkPressed: ({String? textInput}) {
                    signOut();
                  },
                  okButtonText: 'Sign Out',
                  cancelButtonText: 'Cancel',
                ).show(context);
              },
              child: const Text('Sign Out'),
            ),
            ElevatedButton(
              onPressed: () async {
                Popup(
                  false,
                  false,
                  title: 'Delete Account',
                  contentController:
                      'Are you sure you want to delete your account? This action cannot be undone.',
                  onOkPressed: ({
                    String? textInput,
                  }) {
                    deleteAccount(uid);
                  },
                  okButtonText: 'DELETE ACCOUNT',
                  cancelButtonText: 'Cancel',
                ).show(context);
              },
              child: const Text('Delete Account'),
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
