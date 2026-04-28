import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'widgets/kids_doodle_background.dart';

class LeTraceMagiqueApp extends StatelessWidget {
  const LeTraceMagiqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Le Tracé Magique',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF7B61FF),
        scaffoldBackgroundColor: Colors.transparent,
      ),
      builder: (context, child) {
        return KidsDoodleBackground(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeScreen(),
    );
  }
}
