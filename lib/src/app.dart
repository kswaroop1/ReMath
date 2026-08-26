import 'package:flutter/material.dart';
import 'package:remath/src/features/home/presentation/home_screen.dart';

class ReMathApp extends StatelessWidget {
  const ReMathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff375a7f)),
        useMaterial3: true,
      ),
      title: 'ReMath',
    );
  }
}
