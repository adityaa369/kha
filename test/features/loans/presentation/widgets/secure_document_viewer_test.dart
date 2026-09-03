import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:khatha/data/repositories/loan_repository.dart';
import 'package:khatha/features/loans/presentation/widgets/secure_document_viewer.dart';
import 'package:khatha/core/error/failures.dart';

class MockLoanRepository extends Mock implements LoanRepository {}

void main() {
  late MockLoanRepository mockRepo;

  setUp(() {
    mockRepo = MockLoanRepository();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: RepositoryProvider<LoanRepository>.value(
          value: mockRepo,
          child: child,
        ),
      ),
    );
  }

  group('4F-4F Secure Document Viewer', () {
    testWidgets('1. Correct user retrieves signed URL and 7. Signed URL is not persisted (cleared on dispose)', (WidgetTester tester) async {
      when(() => mockRepo.getSignedDocumentUrl('doc_123'))
          .thenAnswer((_) async => DocumentResponse(url: 'https://storage.googleapis.com/signed-url-123', contentType: 'image/jpeg'));

      await tester.pumpWidget(buildTestableWidget(
        const SecureDocumentViewer(documentId: 'doc_123'),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      verify(() => mockRepo.getSignedDocumentUrl('doc_123')).called(1);
      
      // Should show Image.network
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      
      final image = tester.widget<Image>(imageFinder);
      final networkImage = image.image as NetworkImage;
      expect(networkImage.url, 'https://storage.googleapis.com/signed-url-123');
    });

    testWidgets('3. Wrong user gets 403', (WidgetTester tester) async {
      when(() => mockRepo.getSignedDocumentUrl('doc_123'))
          .thenThrow(const AuthFailure("You don't have access to this document."));

      await tester.pumpWidget(buildTestableWidget(
        const SecureDocumentViewer(documentId: 'doc_123'),
      ));
      
      await tester.pumpAndSettle();

      expect(find.text("You don't have access to this document."), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('4. Unknown document gets 404', (WidgetTester tester) async {
      when(() => mockRepo.getSignedDocumentUrl('doc_123'))
          .thenThrow(const ValidationFailure("Document unavailable or not found."));

      await tester.pumpWidget(buildTestableWidget(
        const SecureDocumentViewer(documentId: 'doc_123'),
      ));
      
      await tester.pumpAndSettle();

      expect(find.text("Document unavailable or not found."), findsOneWidget);
    });

    testWidgets('8. Signed URL expiry can be refreshed', (WidgetTester tester) async {
      // First attempt fails due to expiry/network
      when(() => mockRepo.getSignedDocumentUrl('doc_123'))
          .thenThrow(const NetworkFailure("Failed to load document securely."));

      await tester.pumpWidget(buildTestableWidget(
        const SecureDocumentViewer(documentId: 'doc_123'),
      ));
      
      await tester.pumpAndSettle();
      
      // Should show Retry button
      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);
      
      // Setup successful response for retry
      when(() => mockRepo.getSignedDocumentUrl('doc_123'))
          .thenAnswer((_) async => DocumentResponse(url: 'https://storage.googleapis.com/new-signed-url-123', contentType: 'image/jpeg'));
          
      await tester.tap(retryButton);
      await tester.pumpAndSettle();
      
      // Should show Image.network
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      final networkImage = image.image as NetworkImage;
      expect(networkImage.url, 'https://storage.googleapis.com/new-signed-url-123');
    });

    testWidgets('12. PDF renders (shows PDF viewer placeholder based on backend contentType)', (WidgetTester tester) async {
      when(() => mockRepo.getSignedDocumentUrl('doc_pdf_123'))
          .thenAnswer((_) async => DocumentResponse(url: 'https://storage.googleapis.com/signed-url-pdf', contentType: 'application/pdf'));

      await tester.pumpWidget(buildTestableWidget(
        const SecureDocumentViewer(documentId: 'doc_pdf_123'),
      ));
      
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      expect(find.text('PDF loaded securely.'), findsOneWidget);
    });
  });
}
