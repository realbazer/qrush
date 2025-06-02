import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/link.dart';

Future<dynamic> showQRCodeInfo(
  BuildContext context,
  dynamic image,
  List<Barcode> barcodes,
) {
  return showMaterialModalBottomSheet(
    context: context,
    builder:
        (context) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(color: Colors.black),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'QR Code Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.xmark),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 16.0),
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.onPrimary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        image is Uint8List
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.memory(image, fit: BoxFit.cover),
                            )
                            : ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.file(File(image), fit: BoxFit.cover),
                            ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detected ${barcodes.length} barcode(s):',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...barcodes.map((barcode) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                barcode.rawValue ?? 'Unknown content',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              SizedBox(height: 32),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Link(
                                    target: LinkTarget.blank,
                                    uri: Uri.parse(barcode.rawValue ?? ''),
                                    builder:
                                        (context, followLink) =>
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                followLink!();
                                              },
                                              icon: Icon(Icons.open_in_browser),
                                              label: Text('Open'),
                                              style: OutlinedButton.styleFrom(
                                                minimumSize: Size(100, 50),
                                                backgroundColor:
                                                    Theme.of(context).colorScheme.primary,
                                                foregroundColor:
                                                    Theme.of(context).colorScheme.secondary,
                                                side: BorderSide(
                                                  width: 2,
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      SharePlus.instance.share(
                                        ShareParams(
                                          text: barcodes.first.rawValue,
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.share),
                                    label: Text('Share'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: Size(100, 50),
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context).colorScheme.secondary,
                                      side: BorderSide(
                                        width: 2,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: barcodes.first.rawValue!,
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.copy),
                                    label: Text('Copy'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: Size(100, 50),
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context).colorScheme.secondary,
                                      side: BorderSide(
                                        width: 2,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
  );
}
