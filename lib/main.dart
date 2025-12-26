import 'package:flutter/material.dart';
import 'screens/background_editor_page.dart';
import 'services/logger_service.dart';

void main() {
  // Инициализация логирования
  final logger = LoggerService();
  logger.init();
  logger.logInfo(message: 'Application started');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Background Eraser / Blur',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BackgroundEditorPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
