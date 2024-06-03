import 'package:flutter/material.dart';
import 'package:hackernews/pages/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hacker News',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromRGBO(255, 100, 4, 1)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
