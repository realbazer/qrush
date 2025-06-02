import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qrush/pages/scan/widgets/qr_code_info_widget.dart';
import 'package:image_picker/image_picker.dart';

enum ScanMode { scan, upload }

class QRScannerBox extends StatefulWidget {
  final ScanMode scanMode;

  const QRScannerBox({Key? key, required this.scanMode}) : super(key: key);

  @override
  State<QRScannerBox> createState() => _QRScannerBoxState();
}

class _QRScannerBoxState extends State<QRScannerBox> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
    returnImage: true,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  Future<BarcodeCapture?> analyzeImage(
    String path, {
    List<BarcodeFormat> formats = const <BarcodeFormat>[],
  }) {
    return MobileScannerPlatform.instance.analyzeImage(path, formats: formats);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scanMode == ScanMode.upload) {
      return Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_selectedImage != null)
              Positioned(
                top: 175,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onPrimary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(
                      File(_selectedImage!.path),
                      width: 350,
                      height: 350,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              )
            else
              Positioned(
                top: 175,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onPrimary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(CupertinoIcons.photo),
                    iconSize: 48,
                    onPressed: () async {
                      final image = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        setState(() {
                          _selectedImage = image;
                        });
                      }
                    },
                  ),
                ),
              ),
            if (_selectedImage != null)
              FutureBuilder<BarcodeCapture?>(
                future: analyzeImage(
                  _selectedImage!.path,
                  formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData &&
                      snapshot.data != null) {
                    final capture = snapshot.data!;
                    final barcodes = capture.barcodes;
                    final image = _selectedImage;
                    Future.microtask(
                      () => showQRCodeInfo(context, image!.path, barcodes),
                    );
                  }

                  return Container();
                },
              ),
          ],
        ),
      );
    }

    if (widget.scanMode == ScanMode.scan) {
      return Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 175,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onPrimary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: (capture) async {
                      if (_isProcessing) return;
                      setState(() {
                        _isProcessing = true;
                      });

                      final List<Barcode> barcodes = capture.barcodes;
                      final Uint8List? image = capture.image;

                      if (image != null && barcodes.isNotEmpty) {
                        _controller.stop();

                        await showQRCodeInfo(context, image, barcodes);

                        setState(() {
                          _isProcessing = false;
                        });
                        _controller.start();
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
