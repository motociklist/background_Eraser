import 'dart:io' show File, Directory, Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../controllers/image_processing_controller.dart';
import '../widgets/api_key_input.dart';
import '../widgets/provider_selector.dart';
import '../widgets/image_picker_buttons.dart';
import '../widgets/image_display.dart';
import '../widgets/process_buttons.dart';
import '../widgets/blur_slider.dart';
import '../widgets/error_message.dart';
import '../widgets/loading_indicator.dart';
import '../utils/web_download_stub.dart'
    if (dart.library.html) '../utils/web_download.dart';

/// Главный экран приложения для обработки изображений
class BackgroundEditorPage extends StatefulWidget {
  const BackgroundEditorPage({super.key});

  @override
  State<BackgroundEditorPage> createState() => _BackgroundEditorPageState();
}

class _BackgroundEditorPageState extends State<BackgroundEditorPage> {
  late final ImageProcessingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ImageProcessingController();
    _controller.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveImage() async {
    if (_controller.state.processedImage == null) return;

    try {
      if (kIsWeb) {
        // Для веб используем download
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename = 'processed_image_$timestamp.png';
        downloadFileWeb(_controller.state.processedImage!, filename);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Изображение скачано успешно')),
          );
        }
      } else {
        // Для мобильных платформ
        Directory? directory;
        String saveMessage = '';

        if (Platform.isAndroid) {
          // Для Android сохраняем в папку Downloads
          try {
            // Получаем внешнее хранилище
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              // Строим путь к папке Downloads
              // externalDir обычно: /storage/emulated/0/Android/data/.../files
              // Нужно получить: /storage/emulated/0/Download
              final storagePath = externalDir.path;

              // Извлекаем корневой путь хранилища
              String downloadsPath;
              if (storagePath.contains('/Android/')) {
                // Путь до /Android, затем добавляем /Download
                downloadsPath = path.join(
                  storagePath.split('/Android/')[0],
                  'Download',
                );
              } else {
                // Альтернативный путь
                downloadsPath = '/storage/emulated/0/Download';
              }

              directory = Directory(downloadsPath);

              // Создаем папку, если её нет
              if (!await directory.exists()) {
                await directory.create(recursive: true);
              }

              saveMessage = 'Изображение сохранено в папку "Загрузки"';
            } else {
              throw Exception('Не удалось получить доступ к хранилищу');
            }
          } catch (e) {
            // Fallback: используем папку Pictures
            try {
              final externalDir = await getExternalStorageDirectory();
              if (externalDir != null) {
                final picturesPath = path.join(
                  externalDir.path.split('/Android/')[0],
                  'Pictures',
                  'BackgroundEraser',
                );
                directory = Directory(picturesPath);
                if (!await directory.exists()) {
                  await directory.create(recursive: true);
                }
                saveMessage = 'Изображение сохранено в папку "Изображения/BackgroundEraser"';
              } else {
                throw Exception('Не удалось получить доступ');
              }
            } catch (_) {
              // Последний fallback: внутреннее хранилище
              directory = await getApplicationDocumentsDirectory();
              saveMessage = 'Изображение сохранено во внутреннее хранилище приложения';
            }
          }
        } else if (Platform.isIOS) {
          // Для iOS используем папку документов
          directory = await getApplicationDocumentsDirectory();
          saveMessage = 'Изображение сохранено в галерею';
        } else {
          // Для других платформ
          directory = await getApplicationDocumentsDirectory();
          saveMessage = 'Изображение сохранено';
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename = 'processed_image_$timestamp.png';
        final file = File(path.join(directory.path, filename));
        await file.writeAsBytes(_controller.state.processedImage!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(saveMessage),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Eraser / Blur'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: state.isProcessing
          ? const LoadingIndicator(message: 'Обработка изображения...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // API Key Input
                  ApiKeyInput(controller: _controller.apiKeyController),
                  const SizedBox(height: 12),

                  // Provider Selector
                  ProviderSelector(
                    selectedProvider: state.selectedProvider,
                    onChanged: _controller.updateProvider,
                  ),
                  const SizedBox(height: 16),

                  // Image Picker Buttons
                  ImagePickerButtons(
                    onImagePicked: _controller.pickImage,
                  ),
                  const SizedBox(height: 16),

                  // Original Image
                  if (state.selectedImageBytes != null) ...[
                    ImageDisplay(
                      imageBytes: state.selectedImageBytes!,
                      title: 'Original Image:',
                    ),
                    const SizedBox(height: 16),

                    // Process Buttons
                    ProcessButtons(
                      isProcessing: state.isProcessing,
                      onRemoveBackground: _controller.removeBackground,
                      onBlurBackground: _controller.blurBackground,
                    ),
                    const SizedBox(height: 16),

                    // Blur Slider
                    BlurSlider(
                      value: state.blurRadius,
                      onChanged: _controller.updateBlurRadius,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Error Message
                  if (state.errorMessage != null) ...[
                    ErrorMessage(message: state.errorMessage!),
                    const SizedBox(height: 16),
                  ],

                  // Processed Image
                  if (state.processedImage != null) ...[
                    ImageDisplay(
                      imageBytes: state.processedImage!,
                      title: 'Processed Image:',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _saveImage,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Image'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

