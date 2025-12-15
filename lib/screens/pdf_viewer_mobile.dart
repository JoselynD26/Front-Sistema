import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PlatformPdfViewer extends StatefulWidget {
  final Uint8List bytes;
  final String tipo;

  const PlatformPdfViewer({
    super.key,
    required this.bytes,
    required this.tipo,
  });

  @override
  State<PlatformPdfViewer> createState() => _PlatformPdfViewerState();
}

class _PlatformPdfViewerState extends State<PlatformPdfViewer> {
  late PdfViewerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PDF de ${widget.tipo}"),
      ),
      body: SfPdfViewer.memory(
        widget.bytes,
        controller: _controller,
      ),
    );
  }
}
