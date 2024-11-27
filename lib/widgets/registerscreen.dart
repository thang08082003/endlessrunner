import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../models/player_model.dart';
import '../models/game_settings.dart';

class RegisterScreen extends StatelessWidget {
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  RegisterScreen({super.key});

  get highscore => null;

  Future<void> register(BuildContext context) async {
    String displayName = displayNameController.text;
    String email = emailController.text;
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    UserModel? existingUser = await UserModel.getUserByEmail(email);
    if (existingUser != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email already exists')),
      );
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      UserModel newUser = UserModel(
        uid: uid,
        email: email,
        password: password,
        displayName: displayName,
      );
      await newUser.saveToFirestore();

      PlayerModel newPlayer = PlayerModel(
        uid: uid,
        highscore: 0,
      );
      await newPlayer.saveToFirestore();

      GameSettings newSettings = GameSettings(uid: uid);
      await newSettings.saveToFirestore();

      Navigator.pushReplacementNamed(context, '/main_menu');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Xóa trường username
            TextField(
              controller: displayNameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => register(context),
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
