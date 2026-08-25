const fs = require('fs');

let repo = fs.readFileSync('lib/data/repositories/loan_repository.dart', 'utf8');

if (!repo.includes('sendPaymentNudge')) {
    repo = repo.replace(
        'Future<bool> recordPayment(String loanId, int amountPaise) async {',
        `Future<void> sendPaymentNudge(String loanId) async {
    try {
      final response = await apiClient.post(
        '/loans/$loanId/payment-nudge',
        data: {},
      );
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to send nudge');
      }
    } catch (e) {
      if (e.toString().contains('429') || e.toString().contains('recently')) {
        throw Exception('A payment nudge was already sent recently. Please wait 24 hours.');
      }
      rethrow;
    }
  }

  Future<bool> recordPayment(String loanId, int amountPaise) async {`
    );
    fs.writeFileSync('lib/data/repositories/loan_repository.dart', repo, 'utf8');
    console.log('Added nudge to repository.');
}

let cubit = fs.readFileSync('lib/core/blocs/loans/loan_cubit.dart', 'utf8');

if (!cubit.includes('sendPaymentNudge')) {
    cubit = cubit.replace(
        'Future<bool> recordPayment(String loanId, int amountPaise) async {',
        `Future<void> sendPaymentNudge(String loanId) async {
    try {
      // Don't emit loading state to avoid rebuilding the whole page
      await _repository.sendPaymentNudge(loanId);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> recordPayment(String loanId, int amountPaise) async {`
    );
    fs.writeFileSync('lib/core/blocs/loans/loan_cubit.dart', cubit, 'utf8');
    console.log('Added nudge to cubit.');
}
