import 'package:flutter/material.dart';
import 'package:drinksync/features/auth/presentation/auth_gate.dart';

class DrinkSyncApp extends StatelessWidget {
  const DrinkSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DrinkSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD85151))),
      home: const AuthGate(),
    );
  }
}
