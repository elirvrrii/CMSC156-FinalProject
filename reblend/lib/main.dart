import 'package:flutter/material.dart';
import 'pages/main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RecipeApp());
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8FA67A),
          brightness: Brightness.light,
        ),
        fontFamily: 'Georgia', // fallback serif
        scaffoldBackgroundColor: const Color(0xFFF5F1EC),
      ),
      home: const MainScreen(),
    );
  }
}
