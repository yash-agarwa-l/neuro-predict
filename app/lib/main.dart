import 'package:flutter/material.dart';
import 'package:mlapp/presentation/splash_page.dart';

import 'package:mlapp/presentation/theme.dart';

void main() {
  runApp(const NeuroPredictApp());
}

class NeuroPredictApp extends StatelessWidget {
  const NeuroPredictApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroPredict',
      theme: buildDarkTheme(), 
      home: SplashScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}