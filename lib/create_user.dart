import 'package:flutter/material.dart';
import 'home.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({Key? key}) : super(key: key);

  @override
  CreateUserPageState createState() => CreateUserPageState();
}

class CreateUserPageState extends State<CreateUserPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  Map<String, String> errors = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
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
              _buildTextField('Name', nameController, 'name'),
              const SizedBox(height: 10),
              _buildTextField('Email', emailController, 'email'),
              const SizedBox(height: 10),
              _buildTextField('Password', passwordController, 'password',
                  isPassword: true),
              const SizedBox(height: 10),
              _buildTextField('Confirm Password', confirmPasswordController,
                  'confirmPassword',
                  isPassword: true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  
                  errors.clear();

                  if (nameController.text.isEmpty) {
                    _addError('Name is required', 'name');
                  }

                  if (emailController.text.isEmpty) {
                    _addError('Email is required', 'email');
                  }

                  if (passwordController.text.isEmpty) {
                    _addError('Password is required', 'password');
                  }

                  if (passwordController.text !=
                      confirmPasswordController.text) {
                    _addError('Password and Confirm Password do not match',
                        'confirmPassword');
                  }

                  if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
                      .hasMatch(emailController.text)) {
                    _addError('Enter a valid email address', 'email');
                  }

                  if (nameController.text.length < 3) {
                    _addError('Enter a valid name', 'name');
                  }

                  setState(() {});

                  if (errors.isEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HomePage(username: nameController.text),
                      ),
                    );
                  }
                },
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, String errorKey,
      {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            errorText: errors[errorKey],
          ),
        ),
      ],
    );
  }

  void _addError(String message, String errorKey) {
    setState(() {
      errors[errorKey] = message;
    });
  }
}