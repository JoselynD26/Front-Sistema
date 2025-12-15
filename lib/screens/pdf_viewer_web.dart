import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

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
  late String viewId;

  @override
  void initState() {
    super.initState();

    viewId = 'pdf-view-${DateTime.now().millisecondsSinceEpoch}';

    final blob = html.Blob([widget.bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    ui.platformViewRegistry.registerViewFactory(viewId, (int id) {
      final iframe = html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PDF de ${widget.tipo}"),
      ),
      body: HtmlElementView(
        viewType: viewId,
      ),
    );
  }
}
