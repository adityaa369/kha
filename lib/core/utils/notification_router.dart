import '../../config/constants.dart';

class NotificationRouter {
  /// Returns the target route string based on the notification data payload.
  /// If it returns a string, the app should `router.go(route)` or `router.push(route)`.
  /// Returns [AppConstants.notifications] as a safe fallback.
  static String getRouteFromPayload(Map<String, dynamic> data) {
    final eventType = data['eventType'] as String?;
    final referenceId = (data['referenceId'] ?? data['loanId']) as String?;
    final intentId = data['intentId'] as String?;

    switch (eventType) {
      case 'LOAN_CREATED':
      case 'LOAN_RECEIVED':
      case 'LOAN_ACTIVATED':
      case 'AGREEMENT_ACCEPTED':
      case 'PAYMENT_RECEIVED':
      case 'PAYMENT_FAILED':
      case 'LOAN_COMPLETED':
      case 'LOAN_CLOSED':
        if (referenceId != null && referenceId.isNotEmpty) {
          return '${AppConstants.loanDetails}/$referenceId';
        }
        return AppConstants.notifications;

      case 'AGREEMENT_READY':
        if (referenceId != null && referenceId.isNotEmpty) {
          return '${AppConstants.loanApproval}/$referenceId';
        }
        return AppConstants.notifications;

      default:
        // Legacy fallbacks
        final legacyType = data['type'] as String?;
        final legacyLoanId = data['loanId'] as String?;

        if (legacyType == 'ADD_CREDIT_INTENT' && intentId != null) {
          return '/add-credit-approval/$intentId?loanId=${legacyLoanId ?? ''}';
        } else if (legacyType == 'CLOSE_INTENT' && intentId != null) {
          return '/close-loan-approval/$intentId?loanId=${legacyLoanId ?? ''}';
        } else if (legacyType == 'CHIT_AUCTION_START') {
          final ledgerId = data['ledgerId'] ?? '';
          return '/chit-live-auction?ledgerId=$ledgerId';
        } else if (legacyLoanId != null && legacyLoanId.isNotEmpty) {
          return '${AppConstants.loanDetails}/$legacyLoanId';
        }

        return AppConstants.notifications;
    }
  }
}
