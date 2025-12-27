import 'package:flutter/material.dart';
import 'screens/background_editor_page.dart';
import 'services/logger_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация логирования
  final logger = LoggerService();
  logger.init();
  logger.logInfo(message: 'Application started');

  // Инициализация Hive
  try {
    final storageService = StorageService();
    await storageService.init();
    logger.logInfo(message: 'Hive initialized successfully');
  } catch (e) {
    logger.logError(
      message: 'Failed to initialize Hive',
      error: e,
      stackTrace: null,
    );
  }

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
