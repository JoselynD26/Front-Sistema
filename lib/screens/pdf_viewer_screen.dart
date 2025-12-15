import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// 👉 IMPORTS CONDICIONALES
import 'pdf_viewer_web.dart'
    if (dart.library.io) 'pdf_viewer_mobile.dart';

class PdfViewerScreen extends StatelessWidget {
  final Uint8List bytes;
  final String tipo;

  const PdfViewerScreen({
    super.key,
    required this.bytes,
    required this.tipo,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformPdfViewer(
      bytes: bytes,
      tipo: tipo,
    );
  }
}
