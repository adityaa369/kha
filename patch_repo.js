const fs = require('fs');

let repo = fs.readFileSync('lib/data/repositories/loan_repository.dart', 'utf8');
if (!repo.includes('deleteDocument')) {
    repo = repo.replace('Future<String> uploadDocument(', `Future<void> deleteDocument(String documentId) async {
    return await handleApiCall(() async {
      final response = await _api.post(
        '/loans/delete-document',
        data: {'documentId': documentId},
      );
      if (response.data['success'] != true) {
        throw ServerFailure(response.data['message'] ?? 'Failed to delete document');
      }
    });
  }

  Future<String> uploadDocument(`);
    fs.writeFileSync('lib/data/repositories/loan_repository.dart', repo);
}

let cubit = fs.readFileSync('lib/core/blocs/loans/loan_cubit.dart', 'utf8');
if (!cubit.includes('deleteDocument')) {
    cubit = cubit.replace('Future<String> uploadDocument(', `Future<void> deleteDocument(String documentId) async {
    try {
      await _repository.deleteDocument(documentId);
    } catch (e) {
      print('Failed to delete orphaned document $documentId: $e');
    }
  }

  Future<String> uploadDocument(`);
    fs.writeFileSync('lib/core/blocs/loans/loan_cubit.dart', cubit);
}
console.log("Patched");
