import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// Виджет для отображения Native Advanced рекламы
class NativeAdWidget extends StatefulWidget {
  final double? height;
  final AdSize? adSize;

  const NativeAdWidget({
    super.key,
    this.height,
    this.adSize,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  final NativeAdController _controller = NativeAdController();
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadNativeAd();
    }
  }

  Future<void> _loadNativeAd() async {
    if (kIsWeb) {
      return;
    }

    final nativeAd = await AdService.instance.loadNativeAd(
      controller: _controller,
    );

    if (nativeAd != null && mounted) {
      setState(() {
        _isAdLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !_isAdLoaded) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final nativeAd = _controller.nativeAd;
        if (nativeAd == null) {
          return const SizedBox.shrink();
        }

        return Container(
          height: widget.height ?? 300,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: AdWidget(ad: nativeAd),
        );
      },
    );
  }
}

