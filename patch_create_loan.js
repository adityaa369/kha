const fs = require('fs');

let pageContent = fs.readFileSync('lib/features/loans/presentation/pages/create_loan_page.dart', 'utf8');

const newSubmitLogic = `
    if (_selectedDocumentFiles.isNotEmpty) {
      List<String> newlyUploadedDocumentIds = [];
      try {
        for (final file in _selectedDocumentFiles) {
          final bytes = await file.readAsBytes();
          final fileName = p.basename(file.path);
          final fileType = p.extension(file.path).replaceFirst('.', '');
          final documentId = await context.read<LoanCubit>().uploadDocument(
            fileName,
            fileType,
            bytes,
          );
          newlyUploadedDocumentIds.add(documentId);
        }
      } catch (e) {
        // Upload failed midway. Clean up any successful uploads so far.
        for (final id in newlyUploadedDocumentIds) {
          await context.read<LoanCubit>().deleteDocument(id);
        }
        setState(() => _isLoading = false);
        if (mounted) {
          _showUploadFailedDialog(phone, 'Failed to upload document: $e');
        }
        return;
      }
      _finalizeLoanCreation(phone, newlyUploadedDocumentIds);
    } else {
      _finalizeLoanCreation(phone, null);
    }
`;

pageContent = pageContent.replace(
    /if \(_selectedDocumentFiles\.isNotEmpty\) \{[\s\S]*?\} else \{\s*_finalizeLoanCreation\(phone, null\);\s*\}/,
    newSubmitLogic.trim()
);

const finalizePatch = `
  void _finalizeLoanCreation(String phone, List<String>? documentIds) async {
    setState(() => _isLoading = true);
    final cubit = context.read<LoanCubit>();
    final idempotencyKey = const Uuid().v4();

    final loanData = {
      'idempotency_key': idempotencyKey,
      'borrower_phone': phone,
      'borrower_name': _borrowerNameController.text,
      'borrower_aadhar': _aadharController.text,
      'borrower_address': _addressController.text,
      'amountPaise': MoneyUtils.parseRupeesToPaise(_amountController.text),
      'interest_rate': widget.loanType == 'interest_credit'
          ? (double.tryParse(_interestController.text) ?? 0.0)
          : 0.0,
      'duration_months': _calculateMonths(),
      'duration_type': _durationType,
      'start_date': _startDate.toIso8601String(),
      'due_date': _dueDate?.toIso8601String(),
      'notes': _notesController.text,
      'shop_name': _shopNameController.text,
      'type': widget.loanType,
      'documentIds': documentIds,
    };

    final result = await cubit.createLoan(loanData);

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      context.pushReplacement(
        '/loan-success',
        extra: {
          'loan_id': result['id'],
          'borrower_name': _borrowerNameController.text,
          'borrower_phone': phone,
          'amountPaise': MoneyUtils.parseRupeesToPaise(_amountController.text),
        },
      );
    } else {
      // Failure occurred, clean up newly uploaded documents
      if (documentIds != null && documentIds.isNotEmpty) {
        for (final id in documentIds) {
          await cubit.deleteDocument(id);
        }
      }
      if (mounted) {
        final state = cubit.state;
        if (state is LoanError) {
          _showErrorDialog(state.message);
        }
      }
    }
  }
`;

pageContent = pageContent.replace(
    /void _finalizeLoanCreation\(String phone, List<String>\? documentIds\) async \{[\s\S]*?if \(state is LoanError\) \{[\s\S]*?_showErrorDialog\(state\.message\);[\s\S]*?\}[\s\S]*?\}[\s\S]*?\}/,
    finalizePatch.trim()
);

fs.writeFileSync('lib/features/loans/presentation/pages/create_loan_page.dart', pageContent);
