import 'package:flutter/material.dart';
import 'package:qrush/pages/scan/widgets/qr_scanner_box_widget.dart';
import 'package:qrush/pages/scan/widgets/scan_upload_widget.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final ValueNotifier<int> _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = ValueNotifier(0);
  }

  @override
  void dispose() {
    _selectedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Image(
                  image: AssetImage(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/qrush_logo.png'
                        : 'assets/qrush_logo_dark.png',
                  ),
                  fit: BoxFit.contain,
                  width: 160,
                  height: 100,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 550, left: 25, right: 25),
            child: ValueListenableBuilder<int>(
              valueListenable: _selectedIndex,
              builder: (context, value, child) {
                return ScanOrUploadWidget(
                  text1: 'Scan',
                  text2: 'Upload',
                  defaultSelectedIndex: value,
                  onTabChange: (index) {
                    _selectedIndex.value = index;
                  },
                );
              },
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: _selectedIndex,
            builder: (context, value, child) {
              return QRScannerBox(
                scanMode: value == 0 ? ScanMode.scan : ScanMode.upload,
              );
            },
          ),
        ],
      ),
    );
  }
}
