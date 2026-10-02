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
        final fileType = p.extension(file.path).replaceFirst('.', '');
        final documentId = await cubit.uploadDocument(
          fileName,
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
}
