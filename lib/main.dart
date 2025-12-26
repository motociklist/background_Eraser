import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'services/background_service.dart';
import 'utils/web_download_stub.dart'
    if (dart.library.html) 'utils/web_download.dart';

void main() {
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
    );
  }
}

class BackgroundEditorPage extends StatefulWidget {
  const BackgroundEditorPage({super.key});

  @override
  State<BackgroundEditorPage> createState() => _BackgroundEditorPageState();
}

class _BackgroundEditorPageState extends State<BackgroundEditorPage> {
  Uint8List? _selectedImageBytes;
  Uint8List? _processedImage;
  bool _isProcessing = false;
  String? _errorMessage;
  final BackgroundService _backgroundService = BackgroundService();
  final TextEditingController _apiKeyController = TextEditingController();
  String _selectedProvider = 'removebg';
  double _blurRadius = 10.0;

  @override
  void initState() {
    super.initState();
    // Можно загрузить сохраненный API ключ
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        // Загружаем байты изображения для поддержки веба
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _processedImage = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  Future<void> _removeBackground() async {
    if (_selectedImageBytes == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
      });
      return;
    }

    if (_apiKeyController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter API key';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _processedImage = null;
    });

    try {
      _backgroundService.apiKey = _apiKeyController.text;
      _backgroundService.apiProvider = _selectedProvider;

      final result = await _backgroundService.removeBackgroundFromBytes(_selectedImageBytes!);

      if (result != null) {
        setState(() {
          _processedImage = result;
          _isProcessing = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to process image';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _blurBackground() async {
    if (_selectedImageBytes == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
      });
      return;
    }

    if (_apiKeyController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter API key for background removal';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _processedImage = null;
    });

    try {
      _backgroundService.apiKey = _apiKeyController.text;
      _backgroundService.apiProvider = _selectedProvider;

      final result = await _backgroundService.blurBackgroundFromBytes(_selectedImageBytes!, blurRadius: _blurRadius);

      if (result != null) {
        setState(() {
          _processedImage = result;
          _isProcessing = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to blur background';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        // Показываем понятное сообщение об ошибке
        final errorStr = e.toString();
        if (errorStr.contains('Не удалось определить')) {
          _errorMessage = errorStr.replaceAll('Exception: ', '');
        } else if (errorStr.contains('Превышен лимит')) {
          _errorMessage = errorStr.replaceAll('Exception: ', '');
        } else if (errorStr.contains('Неверный API')) {
          _errorMessage = errorStr.replaceAll('Exception: ', '');
        } else {
          _errorMessage = 'Ошибка: ${errorStr.replaceAll('Exception: ', '')}';
        }
        _isProcessing = false;
      });
    }
  }

  Future<void> _saveImage() async {
    if (_processedImage == null) return;

    try {
      if (kIsWeb) {
        // Для веб-платформы используем download через браузер
        await _saveImageWeb(_processedImage!);
      } else {
        // Для мобильных платформ используем обычное сохранение
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${directory.path}/processed_image_$timestamp.png');
        await file.writeAsBytes(_processedImage!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image saved to: ${file.path}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: $e')),
        );
      }
    }
  }

  Future<void> _saveImageWeb(Uint8List imageBytes) async {
    // Для веб используем download через JavaScript
    if (!kIsWeb) return;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'processed_image_$timestamp.png';
      downloadFileWeb(imageBytes, filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Изображение скачано успешно')),
        );
      }
    } catch (e) {
      // Fallback: показываем инструкцию
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Нажмите правой кнопкой на изображение и выберите "Сохранить изображение как..."'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Eraser / Blur'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // API Key Input
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your API key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),

            // API Provider Selection
            DropdownButtonFormField<String>(
              initialValue: _selectedProvider,
              decoration: const InputDecoration(
                labelText: 'API Provider',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'removebg', child: Text('Remove.bg')),
                DropdownMenuItem(value: 'photoroom', child: Text('PhotoRoom')),
                DropdownMenuItem(value: 'clipdrop', child: Text('Clipdrop')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedProvider = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Image Selection Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selected Image
            if (_selectedImageBytes != null) ...[
              const Text('Original Image:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Image.memory(
                _selectedImageBytes!,
                fit: BoxFit.contain,
                height: 300,
              ),
              const SizedBox(height: 16),
            ],

            // Process Buttons
            if (_selectedImageBytes != null) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _removeBackground,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Remove Background'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _blurBackground,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Blur Background'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Blur Radius Slider
              const Text('Blur Radius:', style: TextStyle(fontSize: 14)),
              Slider(
                value: _blurRadius,
                min: 1.0,
                max: 50.0,
                divisions: 49,
                label: _blurRadius.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _blurRadius = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Processed Image
            if (_processedImage != null) ...[
              const SizedBox(height: 16),
              const Text('Processed Image:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Image.memory(
                _processedImage!,
                fit: BoxFit.contain,
                height: 300,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saveImage,
                icon: const Icon(Icons.save),
                label: const Text('Save Image'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
