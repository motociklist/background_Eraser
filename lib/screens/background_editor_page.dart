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
import '../services/logger_service.dart';

/// Главный экран приложения для обработки изображений
class BackgroundEditorPage extends StatefulWidget {
  const BackgroundEditorPage({super.key});

  @override
  State<BackgroundEditorPage> createState() => _BackgroundEditorPageState();
}

class _BackgroundEditorPageState extends State<BackgroundEditorPage> {
  late final ImageProcessingController _controller;
  final LoggerService _logger = LoggerService();

  @override
  void initState() {
    super.initState();
    _logger.init();
    _logger.logAppState(action: 'Screen initialized');
    _controller = ImageProcessingController();
    _controller.addListener(_onStateChanged);
    // Ждем загрузки настроек и обновляем UI
    _controller.loadSettings().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
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
                saveMessage =
                    'Изображение сохранено в папку "Изображения/BackgroundEraser"';
              } else {
                throw Exception('Не удалось получить доступ');
              }
            } catch (_) {
              // Последний fallback: внутреннее хранилище
              directory = await getApplicationDocumentsDirectory();
              saveMessage =
                  'Изображение сохранено во внутреннее хранилище приложения';
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

        _logger.logFileSave(
          path: file.path,
          fileSize: _controller.state.processedImage!.length,
          success: true,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(saveMessage),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      _logger.logFileSave(
        path: '',
        fileSize: 0,
        success: false,
        error: e.toString(),
      );
      _logger.logError(
        message: 'Error saving image',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    final maxContentWidth = isWideScreen ? 800.0 : double.infinity;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.3),
              colorScheme.secondaryContainer.withOpacity(0.2),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: state.isProcessing
              ? const LoadingIndicator(message: 'Обработка изображения...')
              : CustomScrollView(
                  slivers: [
                    // App Bar
                    SliverAppBar(
                      expandedHeight: 120,
                      floating: false,
                      pinned: true,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        title: const Text(
                          'Background Editor',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        centerTitle: true,
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Content
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isWideScreen ? 24.0 : 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Settings Card
                                Card(
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.settings,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Настройки',
                                                style: theme
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        // API Key Input
                                        ApiKeyInput(
                                          controller:
                                              _controller.apiKeyController,
                                        ),
                                        const SizedBox(height: 16),
                                        // Provider Selector
                                        ProviderSelector(
                                          selectedProvider:
                                              state.selectedProvider,
                                          onChanged: _controller.updateProvider,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Image Picker Card
                                Card(
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.image,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Выбор изображения',
                                                style: theme
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        ImagePickerButtons(
                                          onImagePicked: _controller.pickImage,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Original Image
                                if (state.selectedImageBytes != null) ...[
                                  const SizedBox(height: 20),
                                  Card(
                                    elevation: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.photo,
                                                color: colorScheme.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Оригинальное изображение',
                                                  style: theme
                                                      .textTheme
                                                      .titleLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          ImageDisplay(
                                            imageBytes:
                                                state.selectedImageBytes!,
                                            title: '',
                                          ),
                                          const SizedBox(height: 20),
                                          // Process Buttons
                                          ProcessButtons(
                                            isProcessing: state.isProcessing,
                                            onRemoveBackground:
                                                _controller.removeBackground,
                                            onBlurBackground:
                                                _controller.blurBackground,
                                          ),
                                          const SizedBox(height: 20),
                                          // Blur Slider
                                          BlurSlider(
                                            value: state.blurRadius,
                                            onChanged:
                                                _controller.updateBlurRadius,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                // Error Message
                                if (state.errorMessage != null) ...[
                                  const SizedBox(height: 20),
                                  ErrorMessage(message: state.errorMessage!),
                                ],

                                // Processed Image
                                if (state.processedImage != null) ...[
                                  const SizedBox(height: 20),
                                  Card(
                                    elevation: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Обработанное изображение',
                                                  style: theme
                                                      .textTheme
                                                      .titleLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          ImageDisplay(
                                            imageBytes: state.processedImage!,
                                            title: '',
                                          ),
                                          const SizedBox(height: 20),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  colorScheme.primary,
                                                  colorScheme.primary
                                                      .withOpacity(0.8),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: ElevatedButton.icon(
                                              onPressed: _saveImage,
                                              icon: const Icon(
                                                Icons.download,
                                                color: Colors.white,
                                              ),
                                              label: const Text(
                                                'Сохранить изображение',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors
                                                    .transparent, // Прозрачный для градиента
                                                shadowColor: Colors.transparent,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 18,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
