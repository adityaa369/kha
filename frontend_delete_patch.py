import re

# 1. Update loan_repository.dart
with open(lib/data/repositories/loan_repository.dart, 'r', encoding='utf-8') as f:
    repo_content = f.read()

delete_repo_func = """
  Future<void> deleteDocument(String documentId) async {
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
"""

if "Future<void> deleteDocument" not in repo_content:
    repo_content = repo_content.replace(
        "Future<String> uploadDocument(",
        f"{delete_repo_func}\n  Future<String> uploadDocument("
    )
    with open(lib/data/repositories/loan_repository.dart, 'w', encoding='utf-8') as f:
        f.write(repo_content)


# 2. Update loan_cubit.dart
with open(lib/core/blocs/loans/loan_cubit.dart, 'r', encoding='utf-8') as f:
    cubit_content = f.read()

delete_cubit_func = """
  Future<void> deleteDocument(String documentId) async {
    try {
      await _repository.deleteDocument(documentId);
    } catch (e) {
      // Best effort deletion, do not emit error that disrupts UX
      print('Failed to delete orphaned document $documentId: $e');
    }
  }
"""

if "Future<void> deleteDocument" not in cubit_content:
    cubit_content = cubit_content.replace(
        "Future<String> uploadDocument(",
        f"{delete_cubit_func}\n  Future<String> uploadDocument("
    )
    with open(lib/core/blocs/loans/loan_cubit.dart, 'w', encoding='utf-8') as f:
        f.write(cubit_content)

print("Repo and Cubit patched")
