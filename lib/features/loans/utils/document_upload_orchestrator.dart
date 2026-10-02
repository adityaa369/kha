import 'dart:io';
import 'package:khatha/core/blocs/loans/loan_cubit.dart';
import 'package:path/path.dart' as p;

class DocumentUploadOrchestrator {
  final LoanCubit cubit;
  final List<String> existingDocumentIds;

  DocumentUploadOrchestrator(this.cubit, {this.existingDocumentIds = const []});

  Future<List<String>> uploadAndGetIds(List<File> files) async {
    List<String> newlyUploadedDocumentIds = [];
    try {
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final fileName = p.basename(file.path);
        final rawExt = p.extension(file.path).toLowerCase().replaceFirst('.', '');
        // Map extension → MIME type expected by backend. Camera files are always JPEG.
        final fileType = _extToMime(rawExt);
        final documentId = await cubit.uploadDocument(
          // Ensure filename always has an extension so the backend recognises it
          _ensureExtension(fileName, rawExt),
          fileType,
          bytes,
        );
        newlyUploadedDocumentIds.add(documentId);
      }
      return newlyUploadedDocumentIds;
    } catch (e) {
      await cleanup(newlyUploadedDocumentIds);
      rethrow;
    }
  }

  Future<void> cleanup(List<String> newlyUploadedDocumentIds) async {
    for (final id in newlyUploadedDocumentIds) {
      if (!existingDocumentIds.contains(id)) {
        try {
          await cubit.deleteDocument(id);
        } catch (e) {
          print('Cleanup failed for $id: $e');
        }
      }
    }
  }

  /// Maps a file extension to the MIME type expected by the backend.
  /// Falls back to image/jpeg (camera always produces JPEGs).
  static String _extToMime(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Guarantees the filename has a proper extension; appends .jpg if missing.
  static String _ensureExtension(String fileName, String ext) {
    if (ext.isEmpty || p.extension(fileName).isEmpty) {
      return '$fileName.jpg';
    }
    return fileName;
  }
}
