import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart'
    show DataSnapshot, DatabaseEvent, DatabaseReference, FirebaseDatabase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';
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
  bool isGoogleAccount = false;
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    initializeUid();
    checkIfGoogleAccount().then((bool result) {
      setState(() {
        isGoogleAccount = result;
      });
    });
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

  Future<bool> checkIfGoogleAccount() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      for (UserInfo userInfo in user.providerData) {
        if (userInfo.providerId == 'google.com') {
          return true;
        }
      }
    }
    return false;
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
              "The Google Account is Already Linked to Another Account",
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
      User? user = FirebaseAuth.instance.currentUser;
      DatabaseReference usersRef =
          FirebaseDatabase.instance.ref().child('users').child(uid);

      await usersRef.remove();
      SharedPreferences preference = await SharedPreferences.getInstance();
      preference.setString('uid', '');
      preference.setString('name', '');
      preference.setBool('isWorkoutActive', false);

      if (user != null && user.uid == uid) {
        await user.delete();
      }

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
                  return Text(
                    'Hello, ${snapshot.data}!',
                    style: const TextStyle(
                      fontSize: 32, 
                    ),
                  );
                } else {
                  return const SizedBox();
                }
              },
            ),
            const SizedBox(height: 20),
            FutureBuilder(
              future: Future.value(isGoogleAccount),
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.data == true) {
                  return const Text('Google account Connected', style: TextStyle(
                      fontSize: 18, 
                    ));
                } else {
                  return SignInButton(
                    Buttons.googleDark,
                    onPressed: () async {
                      await signInWithGoogle();
                    },
                  );
                }
              },
            ),
            const SizedBox(height: 20),
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
              style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  fixedSize: const Size(320, 40),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero)),
              child: const Text('Edit Name'),
            ),
            const SizedBox(height: 220),
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
              style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                  fixedSize: const Size(320, 40),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero)),
              child: const Text('Sign Out'),
            ),
            const SizedBox(height: 20),
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
              style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                  fixedSize: const Size(320, 40),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero)),
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
