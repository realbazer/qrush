import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

enum QRCodeType { text, url, email, phone, sms, wifi, contact }

class QRCodePreset {
  final String name;
  final QRCodeType type;
  final Color qrColor;
  final Color backgroundColor;
  final double size;
  final int errorCorrectionLevel;
  final bool gapless;
  final QrEyeShape eyeShape;
  final QrDataModuleShape dataModuleShape;
  final String? logoPath;

  QRCodePreset({
    required this.name,
    required this.type,
    required this.qrColor,
    required this.backgroundColor,
    required this.size,
    required this.errorCorrectionLevel,
    required this.gapless,
    required this.eyeShape,
    required this.dataModuleShape,
    this.logoPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.index,
      'qrColor': qrColor.value,
      'backgroundColor': backgroundColor.value,
      'size': size,
      'errorCorrectionLevel': errorCorrectionLevel,
      'gapless': gapless,
      'eyeShape': eyeShape.index,
      'dataModuleShape': dataModuleShape.index,
      'logoPath': logoPath,
    };
  }

  factory QRCodePreset.fromJson(Map<String, dynamic> json) {
    return QRCodePreset(
      name: json['name'],
      type: QRCodeType.values[json['type']],
      qrColor: Color(json['qrColor']),
      backgroundColor: Color(json['backgroundColor']),
      size: json['size'],
      errorCorrectionLevel: json['errorCorrectionLevel'],
      gapless: json['gapless'],
      eyeShape: QrEyeShape.values[json['eyeShape']],
      dataModuleShape: QrDataModuleShape.values[json['dataModuleShape']],
      logoPath: json['logoPath'],
    );
  }
}

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  QRCodeType _selectedType = QRCodeType.text;
  final GlobalKey _qrKey = GlobalKey();

  final _dataController = TextEditingController();
  final _nameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _wifiSsidController = TextEditingController();
  final _wifiPasswordController = TextEditingController();

  String _generatedData = '';
  String _presetName = 'Last saved locally';

  Color _qrColor = Colors.black;
  Color _backgroundColor = Colors.white;
  double _qrSize = 200.0;
  int _errorCorrectionLevel = QrErrorCorrectLevel.L;
  bool _gapless = false;
  QrEyeShape _eyeShape = QrEyeShape.square;
  QrDataModuleShape _dataModuleShape = QrDataModuleShape.square;
  String? _logoPath;

  List<String> _presetNames = ['Last saved locally'];
  List<QRCodePreset> _presets = [];

  static const String lastUsedPresetKey = 'Last saved locally';

  @override
  void initState() {
    super.initState();

    _dataController.addListener(_updateQRCodePreview);
    _nameController.addListener(_updateQRCodePreview);
    _organizationController.addListener(_updateQRCodePreview);
    _phoneController.addListener(_updateQRCodePreview);
    _emailController.addListener(_updateQRCodePreview);
    _wifiSsidController.addListener(_updateQRCodePreview);
    _wifiPasswordController.addListener(_updateQRCodePreview);

    _dataController.text = '';
    _updateQRCodePreview();

    _loadPresets();
  }

  @override
  void dispose() {
    _saveStateDebounce?.cancel();
    _dataController.dispose();
    _nameController.dispose();
    _organizationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _wifiSsidController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  void _updateQRCodePreview() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _generatedData = _formatData();
      });
    }
  }

  String _formatData() {
    switch (_selectedType) {
      case QRCodeType.url:
        return _dataController.text.startsWith('http')
            ? _dataController.text
            : 'https://${_dataController.text}';
      case QRCodeType.email:
        return 'mailto:${_dataController.text}';
      case QRCodeType.phone:
        return 'tel:${_dataController.text}';
      case QRCodeType.sms:
        return 'sms:${_dataController.text}';
      case QRCodeType.wifi:
        String securityType = 'WPA';
        return 'WIFI:S:${_wifiSsidController.text};T:$securityType;P:${_wifiPasswordController.text};;';
      case QRCodeType.contact:
        String mecard = 'MECARD:';
        if (_nameController.text.isNotEmpty)
          mecard += 'N:${_nameController.text};';
        if (_organizationController.text.isNotEmpty)
          mecard += 'ORG:${_organizationController.text};';
        if (_phoneController.text.isNotEmpty)
          mecard += 'TEL:${_phoneController.text};';
        if (_emailController.text.isNotEmpty)
          mecard += 'EMAIL:${_emailController.text};';
        if (_dataController.text.isNotEmpty)
          mecard += 'NOTE:${_dataController.text};';
        mecard += ';';
        return mecard;
      default:
        return _dataController.text;
    }
  }

  Future<String?> _captureAndSavePng() async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/qrcode_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(pngBytes);

      return tempFile.path;
    } catch (e) {
      debugPrint('Error capturing QR code: $e');
      return null;
    }
  }

  Future<bool> _saveToGallery() async {
    try {
      if (Platform.isAndroid) {
        if (await Permission.photos.request().isGranted) {
        } else if (await Permission.storage.request().isGranted) {
        } else {
          return false;
        }
      } else if (Platform.isIOS) {
        if (!await Permission.photos.request().isGranted) {
          return false;
        }
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final random = Random().nextInt(10000).toString().padLeft(4, '0');
      final filename = 'QRCode_${timestamp}_$random';

      final filePath = await _captureAndSavePng();

      await SaverGallery.saveFile(
        filePath: filePath!,
        fileName: filename,
        skipIfExists: true,
      );

      debugPrint('QR code saved to: $filePath');
      return true;
    } catch (e) {
      debugPrint('Error saving to gallery: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrPreview = Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          _generatedData.isNotEmpty
              ? QrImageView(
                data: _generatedData,
                version: QrVersions.auto,
                size: _qrSize,
                backgroundColor: _backgroundColor,
                foregroundColor: _qrColor,
                errorCorrectionLevel: _errorCorrectionLevel,
                gapless: _gapless,
                eyeStyle: QrEyeStyle(eyeShape: _eyeShape, color: _qrColor),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: _dataModuleShape,
                  color: _qrColor,
                ),
                embeddedImage:
                    _logoPath != null ? FileImage(File(_logoPath!)) : null,
                embeddedImageStyle:
                    _logoPath != null
                        ? QrEmbeddedImageStyle(
                          size: Size.square(_qrSize * 0.2),
                          color: Colors.transparent,
                        )
                        : null,
              )
              : const SizedBox(
                width: 200,
                height: 200,
                child: Center(
                  child: Text(
                    'QR code will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
    );

    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'QRush Generator',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: RepaintBoundary(
                              key: _qrKey,
                              child: qrPreview,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () async {
                                  if (_generatedData.isEmpty ||
                                      !(_formKey.currentState?.validate() ??
                                          false)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please fill out all required fields',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final boundary =
                                      _qrKey.currentContext?.findRenderObject()
                                          as RenderRepaintBoundary?;
                                  if (boundary == null) return;

                                  final saved = await _saveToGallery();
                                  if (!context.mounted) return;
                                  if (saved) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'QR code saved to gallery',
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to save QR code'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  CupertinoIcons.arrow_down_to_line,
                                ),
                                tooltip: 'Save QR Code',
                              ),
                              IconButton(
                                onPressed: () async {
                                  if (_generatedData.isEmpty ||
                                      !(_formKey.currentState?.validate() ??
                                          false)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please fill out all required fields',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final path = await _captureAndSavePng();
                                  if (!context.mounted) return;

                                  if (path != null) {
                                    await Share.shareXFiles([
                                      XFile(path),
                                    ], text: 'QR Code');
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Failed to share QR code',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(CupertinoIcons.share),
                                tooltip: 'Share QR Code',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'QR Code Type',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade600,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<QRCodeType>(
                                    isExpanded: true,
                                    value: _selectedType,
                                    dropdownColor:
                                        Theme.of(context).colorScheme.primary,
                                    items:
                                        QRCodeType.values.map((type) {
                                          return DropdownMenuItem(
                                            value: type,
                                            child: Text(
                                              type.name.toUpperCase(),
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedType = value;
                                          _updateQRCodePreview();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Preset',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade600,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _presetName,
                                    dropdownColor:
                                        Theme.of(context).colorScheme.primary,
                                    items:
                                        _presetNames.map((name) {
                                          return DropdownMenuItem(
                                            value: name,
                                            child: Text(name),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        _loadPreset(value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (_presetName != lastUsedPresetKey) {
                                        _loadPreset(_presetName);
                                      }
                                    },
                                    icon: const Icon(
                                      CupertinoIcons.arrow_counterclockwise,
                                    ),
                                    tooltip: 'Load Configuration',
                                    color: Colors.grey,
                                  ),
                                  IconButton(
                                    onPressed: _saveCurrentConfigAsPreset,
                                    icon: const Icon(
                                      CupertinoIcons.add_circled,
                                    ),
                                    tooltip: 'Save Configuration',
                                    color: Colors.grey,
                                  ),
                                  if (_presetName != lastUsedPresetKey)
                                    IconButton(
                                      onPressed:
                                          () => _deletePreset(_presetName),
                                      icon: const Icon(CupertinoIcons.trash),
                                      tooltip: 'Delete Preset',
                                      color: Colors.grey,
                                    ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data to encode',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              if (_selectedType == QRCodeType.wifi) ...[
                                TextFormField(
                                  controller: _wifiSsidController,
                                  decoration: InputDecoration(
                                    labelText: 'WiFi Network Name (SSID)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          (value == null || value.isEmpty)
                                              ? 'Please enter SSID'
                                              : null,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _wifiPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'WiFi Password',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  obscureText: true,
                                ),
                              ] else if (_selectedType ==
                                  QRCodeType.contact) ...[
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          (value == null || value.isEmpty)
                                              ? 'Please enter a name'
                                              : null,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _organizationController,
                                  decoration: InputDecoration(
                                    labelText: 'Organization',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    labelText: 'Phone',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _dataController,
                                  decoration: InputDecoration(
                                    labelText: 'Notes',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  maxLines: 2,
                                ),
                              ] else ...[
                                TextFormField(
                                  controller: _dataController,
                                  decoration: InputDecoration(
                                    labelText: 'Enter data',
                                    hintText: _getHintText(),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter data to encode';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Logo image URL',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade600,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _logoPath ?? 'No logo selected',
                                    style: TextStyle(
                                      color:
                                          _logoPath != null
                                              ? Colors.white
                                              : Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _pickAndSetLogo,
                                icon: const Icon(Icons.upload_file),
                                tooltip: 'Upload image',
                              ),
                              if (_logoPath != null)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _logoPath = null;
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                  tooltip: 'Remove logo',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Background',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final color = await showColorPicker(
                                context,
                                _backgroundColor,
                              );
                              if (color != null) {
                                setState(() => _backgroundColor = color);
                              }
                            },
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: _backgroundColor,
                                border: Border.all(color: Colors.grey.shade600),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dots',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final color = await showColorPicker(
                                context,
                                _qrColor,
                              );
                              if (color != null) {
                                setState(() => _qrColor = color);
                              }
                            },
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: _qrColor,
                                border: Border.all(color: Colors.grey.shade600),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Corners Shape',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade600),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<QrEyeShape>(
                                isExpanded: true,
                                value: _eyeShape,
                                dropdownColor:
                                    Theme.of(context).colorScheme.primary,
                                items:
                                    QrEyeShape.values.map((shape) {
                                      return DropdownMenuItem(
                                        value: shape,
                                        child: Text(shape.name),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _eyeShape = value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dots Shape',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade600),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<QrDataModuleShape>(
                                isExpanded: true,
                                value: _dataModuleShape,
                                dropdownColor:
                                    Theme.of(context).colorScheme.primary,
                                items:
                                    QrDataModuleShape.values.map((shape) {
                                      return DropdownMenuItem(
                                        value: shape,
                                        child: Text(shape.name),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _dataModuleShape = value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error Correction',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade600),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: _errorCorrectionLevel,
                                dropdownColor:
                                    Theme.of(context).colorScheme.primary,
                                items: [
                                  DropdownMenuItem(
                                    value: QrErrorCorrectLevel.L,
                                    child: Text('Low (7%)'),
                                  ),
                                  DropdownMenuItem(
                                    value: QrErrorCorrectLevel.M,
                                    child: Text('Medium (15%)'),
                                  ),
                                  DropdownMenuItem(
                                    value: QrErrorCorrectLevel.Q,
                                    child: Text('Quartile (25%)'),
                                  ),
                                  DropdownMenuItem(
                                    value: QrErrorCorrectLevel.H,
                                    child: Text('High (30%)'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(
                                      () => _errorCorrectionLevel = value,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Gapless toggle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gapless',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _gapless ? 'On' : 'Off',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            value: _gapless,
                            onChanged: (value) {
                              setState(() => _gapless = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Width control
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Width (px)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${_qrSize.toInt()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          '100',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor:
                                  Theme.of(context).colorScheme.secondary,
                              inactiveTrackColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.3),
                              thumbColor:
                                  Theme.of(context).colorScheme.secondary,
                              overlayColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2),
                              trackHeight: 4.0,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8.0,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16.0,
                              ),
                            ),
                            child: Slider(
                              value: _qrSize,
                              min: 100,
                              max: 400,
                              divisions: 30,
                              onChanged: (double value) {
                                setState(() => _qrSize = value);
                              },
                            ),
                          ),
                        ),
                        const Text(
                          '400',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Icon _getPrefixIconForType() {
    switch (_selectedType) {
      case QRCodeType.url:
        return const Icon(Icons.link);
      case QRCodeType.email:
        return const Icon(Icons.email);
      case QRCodeType.phone:
        return const Icon(Icons.phone);
      case QRCodeType.sms:
        return const Icon(Icons.sms);
      case QRCodeType.wifi:
        return const Icon(Icons.wifi);
      case QRCodeType.contact:
        return const Icon(Icons.contact_page);
      default:
        return const Icon(Icons.text_fields);
    }
  }

  String _getHintText() {
    switch (_selectedType) {
      case QRCodeType.url:
        return 'Enter URL (e.g., example.com)';
      case QRCodeType.email:
        return 'Enter email address';
      case QRCodeType.phone:
        return 'Enter phone number';
      case QRCodeType.sms:
        return 'Enter phone number for SMS';
      case QRCodeType.wifi:
        return 'Enter WiFi network name (SSID)';
      case QRCodeType.contact:
        return 'Enter notes for contact (optional)';
      default:
        return 'Enter text';
    }
  }

  Future<Color?> showColorPicker(
    BuildContext context,
    Color initialColor,
  ) async {
    return showDialog<Color>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Pick a color'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children:
                        [
                              ...Colors.primaries,
                              Colors.black,
                              Colors.white,
                              Colors.grey,
                            ]
                            .map(
                              (color) => GestureDetector(
                                onTap: () => Navigator.of(context).pop(color),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _pickAndSetLogo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();

        if (fileSize > 2 * 1024 * 1024) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image too large (max 2MB)')),
          );
          return;
        }

        setState(() {
          _logoPath = pickedFile.path;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo added successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error picking logo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick logo image')),
      );
    }
  }

  Future<void> _saveCurrentStateToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final currentState = QRCodePreset(
        name: lastUsedPresetKey,
        type: _selectedType,
        qrColor: _qrColor,
        backgroundColor: _backgroundColor,
        size: _qrSize,
        errorCorrectionLevel: _errorCorrectionLevel,
        gapless: _gapless,
        eyeShape: _eyeShape,
        dataModuleShape: _dataModuleShape,
        logoPath: _logoPath,
      );

      await prefs.setString(
        'qr_last_state',
        json.encode(currentState.toJson()),
      );

      debugPrint('Current state saved to local storage');
    } catch (e) {
      debugPrint('Error saving current state: $e');
    }
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);

    _debounceStateSave();
  }

  Timer? _saveStateDebounce;
  void _debounceStateSave() {
    if (_saveStateDebounce?.isActive ?? false) _saveStateDebounce!.cancel();
    _saveStateDebounce = Timer(const Duration(milliseconds: 500), () {
      _saveCurrentStateToLocalStorage();
    });
  }

  Future<void> _loadPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lastStateJson = prefs.getString('qr_last_state');
      if (lastStateJson != null) {
        try {
          final lastState = QRCodePreset.fromJson(json.decode(lastStateJson));

          setState(() {
            _selectedType = lastState.type;
            _qrColor = lastState.qrColor;
            _backgroundColor = lastState.backgroundColor;
            _qrSize = lastState.size;
            _errorCorrectionLevel = lastState.errorCorrectionLevel;
            _gapless = lastState.gapless;
            _eyeShape = lastState.eyeShape;
            _dataModuleShape = lastState.dataModuleShape;
            _logoPath = lastState.logoPath;

            _updateQRCodePreview();
          });
          debugPrint('Last state loaded successfully');
        } catch (e) {
          debugPrint('Error parsing last state: $e');
        }
      }

      final presetData = prefs.getStringList('qr_presets') ?? [];

      if (presetData.isNotEmpty) {
        try {
          final loadedPresets = <QRCodePreset>[];

          for (final preset in presetData) {
            try {
              loadedPresets.add(QRCodePreset.fromJson(json.decode(preset)));
            } catch (e) {
              debugPrint('Error parsing preset: $e');
            }
          }

          setState(() {
            _presets = loadedPresets;
            _presetNames = _presets.map((preset) => preset.name).toList();

            if (!_presetNames.contains(lastUsedPresetKey)) {
              _presetNames.insert(0, lastUsedPresetKey);
            }
          });

          debugPrint('Loaded ${_presets.length} presets successfully');
        } catch (e) {
          debugPrint('Error loading presets: $e');

          setState(() {
            _presetNames = [lastUsedPresetKey];
          });
        }
      } else {
        setState(() {
          _presetNames = [lastUsedPresetKey];
          _presets = [];
        });
      }
    } catch (e) {
      debugPrint('Error in _loadPresets: $e');

      setState(() {
        _presetNames = [lastUsedPresetKey];
        _presets = [];
      });
    }
  }

  void _loadPreset(String presetName) {
    if (presetName == lastUsedPresetKey) {
      return;
    }

    try {
      final preset = _presets.firstWhere(
        (p) => p.name == presetName,
        orElse: () {
          throw Exception('Preset not found: $presetName');
        },
      );

      setState(() {
        _selectedType = preset.type;
        _qrColor = preset.qrColor;
        _backgroundColor = preset.backgroundColor;
        _qrSize = preset.size;
        _errorCorrectionLevel = preset.errorCorrectionLevel;
        _gapless = preset.gapless;
        _eyeShape = preset.eyeShape;
        _dataModuleShape = preset.dataModuleShape;
        _logoPath = preset.logoPath;
        _presetName = presetName;

        _updateQRCodePreview();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Loaded preset "$presetName"')));
    } catch (e) {
      debugPrint('Error loading preset: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load preset: ${e.toString()}')),
      );
    }
  }

  Future<void> _deletePreset(String presetName) async {
    if (presetName == lastUsedPresetKey) {
      return;
    }

    try {
      setState(() {
        _presets.removeWhere((p) => p.name == presetName);
        _presetNames = [lastUsedPresetKey, ..._presets.map((p) => p.name)];

        if (_presetName == presetName) {
          _presetName = lastUsedPresetKey;
        }
      });

      final prefs = await SharedPreferences.getInstance();
      final presetJsonList =
          _presets.map((p) => json.encode(p.toJson())).toList();
      await prefs.setStringList('qr_presets', presetJsonList);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleted preset "$presetName"')));
    } catch (e) {
      debugPrint('Error deleting preset: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete preset')));
    }
  }

  Future<void> _saveCurrentConfigAsPreset() async {
    try {
      final TextEditingController nameController = TextEditingController();

      final name = await showDialog<String>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Save Configuration'),
              content: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Preset Name',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.of(context).pop(nameController.text),
                  child: const Text('Save'),
                ),
              ],
            ),
      );

      if (name != null && name.isNotEmpty) {
        final preset = QRCodePreset(
          name: name,
          type: _selectedType,
          qrColor: _qrColor,
          backgroundColor: _backgroundColor,
          size: _qrSize,
          errorCorrectionLevel: _errorCorrectionLevel,
          gapless: _gapless,
          eyeShape: _eyeShape,
          dataModuleShape: _dataModuleShape,
          logoPath: _logoPath,
        );

        _presets.removeWhere((p) => p.name == name);

        _presets.add(preset);

        setState(() {
          _presetNames = _presets.map((p) => p.name).toList();
          if (!_presetNames.contains('Last saved locally')) {
            _presetNames.insert(0, 'Last saved locally');
          }
          _presetName = name;
        });

        final prefs = await SharedPreferences.getInstance();
        final presetJsonList =
            _presets.map((p) => json.encode(p.toJson())).toList();
        await prefs.setStringList('qr_presets', presetJsonList);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Preset "$name" saved')));
      }
    } catch (e) {
      debugPrint('Error saving preset: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save preset')));
    }
  }
}
