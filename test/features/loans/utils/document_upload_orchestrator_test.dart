import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khatha/core/blocs/loans/loan_cubit.dart';
import 'package:khatha/features/loans/utils/document_upload_orchestrator.dart';

class MockLoanCubit extends Mock implements LoanCubit {}
class MockFile extends Mock implements File {}

void main() {
  late MockLoanCubit mockCubit;
  late DocumentUploadOrchestrator orchestrator;

  setUp(() {
    mockCubit = MockLoanCubit();
    orchestrator = DocumentUploadOrchestrator(mockCubit);
    registerFallbackValue(<int>[]);
  });

  MockFile createMockFile(String path) {
    final file = MockFile();
    when(() => file.path).thenReturn(path);
    when(() => file.readAsBytes()).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
    return file;
  }

  group('DocumentUploadOrchestrator Tests', () {
    test('A. upload 3 files -> createLoan succeeds -> files remain', () async {
      final f1 = createMockFile('f1.jpg');
      final f2 = createMockFile('f2.jpg');
      final f3 = createMockFile('f3.jpg');

      when(() => mockCubit.uploadDocument('f1.jpg', 'jpg', any())).thenAnswer((_) async => 'doc1');
      when(() => mockCubit.uploadDocument('f2.jpg', 'jpg', any())).thenAnswer((_) async => 'doc2');
      when(() => mockCubit.uploadDocument('f3.jpg', 'jpg', any())).thenAnswer((_) async => 'doc3');

      final ids = await orchestrator.uploadAndGetIds([f1, f2, f3]);
      expect(ids, ['doc1', 'doc2', 'doc3']);
      
      verifyNever(() => mockCubit.deleteDocument(any()));
    });

    test('B. upload 3 files -> createLoan fails -> all 3 new files cleaned up', () async {
      final f1 = createMockFile('f1.jpg');
      final f2 = createMockFile('f2.jpg');
      final f3 = createMockFile('f3.jpg');

      when(() => mockCubit.uploadDocument('f1.jpg', 'jpg', any())).thenAnswer((_) async => 'doc1');
      when(() => mockCubit.uploadDocument('f2.jpg', 'jpg', any())).thenAnswer((_) async => 'doc2');
      when(() => mockCubit.uploadDocument('f3.jpg', 'jpg', any())).thenAnswer((_) async => 'doc3');
      when(() => mockCubit.deleteDocument(any())).thenAnswer((_) async {});

      final ids = await orchestrator.uploadAndGetIds([f1, f2, f3]);
      
      // Simulate createLoan failure
      await orchestrator.cleanup(ids);

      verify(() => mockCubit.deleteDocument('doc1')).called(1);
      verify(() => mockCubit.deleteDocument('doc2')).called(1);
      verify(() => mockCubit.deleteDocument('doc3')).called(1);
    });

    test('C. upload 1 succeeds, upload 2 fails -> file 1 cleaned up', () async {
      final f1 = createMockFile('f1.jpg');
      final f2 = createMockFile('f2.jpg');

      when(() => mockCubit.uploadDocument('f1.jpg', 'jpg', any())).thenAnswer((_) async => 'doc1');
      when(() => mockCubit.uploadDocument('f2.jpg', 'jpg', any())).thenThrow(Exception('Upload failed'));
      when(() => mockCubit.deleteDocument(any())).thenAnswer((_) async {});

      expect(() => orchestrator.uploadAndGetIds([f1, f2]), throwsException);

      // Verify file 1 was cleaned up in the catch block of uploadAndGetIds
      await Future.delayed(Duration.zero); // ensure async cleanup completes
      verify(() => mockCubit.deleteDocument('doc1')).called(1);
      verifyNever(() => mockCubit.deleteDocument('doc2'));
    });

    test('D. existing document IDs are never deleted', () async {
      final existingOrchestrator = DocumentUploadOrchestrator(mockCubit, existingDocumentIds: ['existing_doc']);
      
      when(() => mockCubit.deleteDocument(any())).thenAnswer((_) async {});

      await existingOrchestrator.cleanup(['existing_doc', 'new_doc']);

      verify(() => mockCubit.deleteDocument('new_doc')).called(1);
      verifyNever(() => mockCubit.deleteDocument('existing_doc'));
    });

    test('E. cleanup failure does not replace the original error', () async {
      final f1 = createMockFile('f1.jpg');
      final f2 = createMockFile('f2.jpg');

      when(() => mockCubit.uploadDocument('f1.jpg', 'jpg', any())).thenAnswer((_) async => 'doc1');
      when(() => mockCubit.uploadDocument('f2.jpg', 'jpg', any())).thenThrow(Exception('Original Upload Error'));
      
      // Simulate cleanup failure
      when(() => mockCubit.deleteDocument(any())).thenThrow(Exception('Cleanup Failed'));

      try {
        await orchestrator.uploadAndGetIds([f1, f2]);
        fail('Should have thrown');
      } catch (e) {
        // Original error is preserved
        expect(e.toString(), contains('Original Upload Error'));
      }

      verify(() => mockCubit.deleteDocument('doc1')).called(1);
    });
  });
}
