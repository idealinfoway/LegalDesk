import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path/path.dart' as p;

class PdfEditorService {
  /// Render all pages of a PDF as PNG thumbnail bytes.
  static Future<List<Uint8List>> renderThumbnails(
    String pdfPath, {
    double dpi = 72,
  }) async {
    final file = File(pdfPath);
    if (!await file.exists()) return [];
    final bytes = await file.readAsBytes();
    final thumbnails = <Uint8List>[];

    await for (final page in Printing.raster(bytes, dpi: dpi)) {
      thumbnails.add(await page.toPng());
    }
    return thumbnails;
  }

  /// Rebuild the PDF at [pdfPath] keeping only the pages listed in
  /// [newPageOrder] (indices into the original page list).
  static Future<void> reorderAndSave(
    String pdfPath,
    List<int> newPageOrder,
  ) async {
    final sourceBytes = await File(pdfPath).readAsBytes();

    // Rasterise every page at 150 dpi, then rebuild in the requested order.
    final allPageImages = <Uint8List>[];
    await for (final raster in Printing.raster(sourceBytes, dpi: 150)) {
      allPageImages.add(await raster.toPng());
    }

    final output = pw.Document();
    for (final idx in newPageOrder) {
      final imgBytes = allPageImages[idx];
      final pageFormat = await _pageFormatFromImage(imgBytes);
      final image = pw.MemoryImage(imgBytes);
      output.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(image, fit: pw.BoxFit.cover),
          ),
        ),
      );
    }

    await File(pdfPath).writeAsBytes(await output.save());
  }

  /// Append [sourcePaths] (PDFs or images) to the end of [targetPdfPath].
  static Future<void> appendFiles(
    String targetPdfPath,
    List<String> sourcePaths,
  ) async {
    final targetBytes = await File(targetPdfPath).readAsBytes();

    // Rasterise existing pages
    final existingImages = <Uint8List>[];
    await for (final raster in Printing.raster(targetBytes, dpi: 150)) {
      existingImages.add(await raster.toPng());
    }

    // Rasterise / load new source pages
    final newImages = <Uint8List>[];
    for (final path in sourcePaths) {
      final ext = p.extension(path).toLowerCase();
      if (ext == '.pdf') {
        final pdfBytes = await File(path).readAsBytes();
        await for (final raster in Printing.raster(pdfBytes, dpi: 150)) {
          newImages.add(await raster.toPng());
        }
      } else {
        // jpg / png — read raw bytes
        newImages.add(await File(path).readAsBytes());
      }
    }

    final output = pw.Document();
    for (final imgBytes in [...existingImages, ...newImages]) {
      final pageFormat = await _pageFormatFromImage(imgBytes);
      final image = pw.MemoryImage(imgBytes);
      output.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(image, fit: pw.BoxFit.cover),
          ),
        ),
      );
    }

    await File(targetPdfPath).writeAsBytes(await output.save());
  }

  /// Decode image bytes and return a PdfPageFormat matching the image's
  /// native dimensions (in PDF points at 72 dpi).
  static Future<PdfPageFormat> _pageFormatFromImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width.toDouble();
      final h = frame.image.height.toDouble();
      frame.image.dispose();
      // Convert pixels to PDF points (72 pt/inch) assuming 150 dpi source
      const dpi = 150.0;
      return PdfPageFormat(w * 72.0 / dpi, h * 72.0 / dpi);
    } catch (_) {
      return PdfPageFormat.a4;
    }
  }
}
