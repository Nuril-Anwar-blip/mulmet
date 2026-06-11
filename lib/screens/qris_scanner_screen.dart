import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_theme.dart';
import '../utils/qris_parser.dart';

class QrisScannerScreen extends StatefulWidget {
  const QrisScannerScreen({super.key});

  @override
  State<QrisScannerScreen> createState() => _QrisScannerScreenState();
}

class _QrisScannerScreenState extends State<QrisScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _handled = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_handled) return;

    String? rawValue;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        rawValue = value;
        break;
      }
    }

    if (rawValue == null) return;

    final parsed = QrisParser.parse(rawValue);
    if (parsed == null) {
      setState(() {
        _errorMessage = 'Kode QR tidak dikenali sebagai QRIS.';
      });
      return;
    }

    _handled = true;
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Scan QRIS',
          style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                final torch = state.torchState;
                return Icon(
                  torch == TorchState.on ? Icons.flash_on : Icons.flash_off,
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.no_photography_outlined,
                          color: Colors.white70, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Kamera tidak tersedia',
                        style: GoogleFonts.hankenGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.errorDetails?.message ??
                            'Izinkan akses kamera di pengaturan perangkat.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.hankenGrotesk(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.onPrimaryContainer, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 32,
            child: Column(
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hankenGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Arahkan kamera ke kode QR merchant. '
                    'Nominal akan terisi otomatis jika tersedia di QR.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
