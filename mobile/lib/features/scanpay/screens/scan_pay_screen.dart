// scan_pay_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import 'payment_uri_parser.dart';

class ScanPayScreen extends StatefulWidget {
  const ScanPayScreen({super.key, required this.onPaymentDetected});

  /// Called with a validated payment request once a QR (camera or gallery)
  /// resolves to a parseable address/amount/chain.
  final void Function(ParsedPaymentRequest request) onPaymentDetected;

  @override
  State<ScanPayScreen> createState() => _ScanPayScreenState();
}

class _ScanPayScreenState extends State<ScanPayScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handledOnce = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleRawValue(String? raw) {
    if (raw == null || _handledOnce) return;
    final parsed = PaymentUriParser.tryParse(raw);
    if (parsed == null) {
      setState(() => _error = 'This QR code doesn\'t contain a recognized wallet address.');
      return;
    }
    _handledOnce = true;
    widget.onPaymentDetected(parsed);
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    // mobile_scanner supports analyzing a static image file directly.
    final capture = await _controller.analyzeImage(file.path);
    if (capture == null || capture.barcodes.isEmpty) {
      setState(() => _error = 'No QR code found in that image.');
      return;
    }
    _handleRawValue(capture.barcodes.first.rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan to Pay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Upload from gallery',
            onPressed: _pickFromGallery,
          ),
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (capture.barcodes.isNotEmpty) {
                _handleRawValue(capture.barcodes.first.rawValue);
              }
            },
          ),
          // Viewfinder frame
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          if (_error != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
