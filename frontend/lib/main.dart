import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:frontend/base_page.dart';
import 'package:frontend/core/theme/theme.dart';

void main() {
  runApp(
    ProviderScope(
      // Add ProviderScope at the root
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PiQuick Objects',
      theme: AppTheme.darkThemeMode,
      home: const BasePage(),
    );
  }
}
