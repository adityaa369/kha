import 'package:flutter_test/flutter_test.dart';
import 'package:khatha/core/utils/notification_router.dart';
import 'package:khatha/config/constants.dart';

void main() {
  group('NotificationRouter', () {
    test('routes to loan details for loan events with referenceId', () {
      final payload = {
        'eventType': 'LOAN_CREATED',
        'referenceId': 'loan123',
      };
      
      final route = NotificationRouter.getRouteFromPayload(payload);
      
      expect(route, '${AppConstants.loanDetails}/loan123');
    });

    test('falls back to loanId if referenceId is null', () {
      final payload = {
        'eventType': 'PAYMENT_RECEIVED',
        'loanId': 'loan456',
      };
      
      final route = NotificationRouter.getRouteFromPayload(payload);
      
      expect(route, '${AppConstants.loanDetails}/loan456');
    });

    test('routes to notifications if referenceId is missing', () {
      final payload = {
        'eventType': 'LOAN_CREATED',
      };
      
      final route = NotificationRouter.getRouteFromPayload(payload);
      
      expect(route, AppConstants.notifications);
    });

    test('routes to loan approval for AGREEMENT_READY', () {
      final payload = {
        'eventType': 'AGREEMENT_READY',
        'referenceId': 'loan789',
      };
      
      final route = NotificationRouter.getRouteFromPayload(payload);
      
      expect(route, '${AppConstants.loanApproval}/loan789');
    });

    test('handles legacy CLOSE_INTENT payload', () {
      final payload = {
        'type': 'CLOSE_INTENT',
        'intentId': 'intent1',
        'loanId': 'loan1',
      };
      
      final route = NotificationRouter.getRouteFromPayload(payload);
      
      expect(route, '/close-loan-approval/intent1?loanId=loan1');
    });
    
    test('handles legacy ADD_CREDIT_INTENT payload', () {
      final payload = {
        'type': 'ADD_CREDIT_INTENT',
        'intentId': 'intent2',
        'loanId': 'loan2',
      };
      
      final route = NotificationRouter.getRouteFromPayload(payload);
      
      expect(route, '/add-credit-approval/intent2?loanId=loan2');
    });

    test('handles unknown event types by falling back to notification center', () {
      final payload = {
        'eventType': 'UNKNOWN_EVENT_TYPE',
        'referenceId': '123',
      };
      
      final route = NotificationRouter.getRouteFromPayload(payload);
      
      expect(route, AppConstants.notifications);
    });
  });
}
