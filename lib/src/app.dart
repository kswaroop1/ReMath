import 'package:flutter/material.dart';
import 'package:remath/src/features/home/presentation/home_screen.dart';
import 'package:remath/src/features/learning/domain/progress_repository.dart';

class ReMathApp extends StatelessWidget {
  const ReMathApp({required this.repository, super.key});

  final ProgressRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(repository: repository),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff375a7f)),
        useMaterial3: true,
      ),
      title: 'ReMath',
    );
  }
}
