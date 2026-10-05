/// Converts raw/technical error text into a short, human-friendly message.
///
/// Every error shown to the user (dialogs, snackbars, inline error views)
/// should pass through [UserMessage.friendly] so that stack traces, exception
/// class names, HTTP codes, field names, or backend jargon never reach the UI.
class UserMessage {
  UserMessage._();

  static const String generic = 'Something went wrong. Please try again.';
  static const String noInternet =
      'No internet connection. Please check your network and try again.';
  static const String timeout =
      'This is taking longer than usual. Please try again.';
  static const String server =
      'We are having trouble right now. Please try again in a moment.';
  static const String session =
      'Your session has expired. Please log in again.';

  static String friendly(Object? raw) {
    if (raw == null) return generic;
    String msg = raw.toString().trim();
    if (msg.isEmpty) return generic;

    final lower = msg.toLowerCase();

    // ── Connectivity ────────────────────────────────────────────────
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('connection error') ||
        lower.contains('network is unreachable') ||
        lower.contains('no internet') ||
        lower.contains('network error') ||
        lower.contains('network-request-failed')) {
      return noInternet;
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return timeout;
    }

    // ── Firebase / OTP ──────────────────────────────────────────────
    if (lower.contains('invalid-verification-code') ||
        lower.contains('invalid verification code') ||
        lower.contains('otp_invalid') ||
        lower.contains('invalid otp')) {
      return 'The OTP you entered is incorrect. Please try again.';
    }
    if (lower.contains('session-expired') ||
        lower.contains('otp_expired') ||
        lower.contains('code-expired')) {
      return 'This OTP has expired. Please request a new one.';
    }
    if (lower.contains('too-many-requests') ||
        lower.contains('too many') ||
        lower.contains('otp_locked')) {
      return 'Too many attempts. Please wait a while and try again.';
    }
    if (lower.contains('quota-exceeded')) {
      return 'OTP limit reached for now. Please try again later.';
    }
    if (lower.contains('invalid-phone-number')) {
      return 'Please enter a valid mobile number.';
    }

    // ── Auth / permission ───────────────────────────────────────────
    if (lower.contains('jwt') ||
        lower.contains('token expired') ||
        lower.contains('unauthorized') ||
        lower.contains('unauthenticated') ||
        lower.contains('status code of 401')) {
      return session;
    }
    if (lower.contains('forbidden') || lower.contains('status code of 403')) {
      return 'You do not have permission to do this.';
    }

    // ── Known business cases ────────────────────────────────────────
    if (lower.contains('overpayment') ||
        lower.contains('exceeds outstanding')) {
      return 'The amount entered is more than the outstanding balance.';
    }
    if (lower.contains('terminal state') ||
        lower.contains('already closed')) {
      return 'This credit is already closed.';
    }
    if (lower.contains('frozen')) {
      return 'This credit is currently on hold.';
    }
    if (lower.contains('amountpaise') || lower.contains('invalid amount')) {
      return 'Please enter a valid amount.';
    }
    if (lower.contains('intent') &&
        (lower.contains('expired') || lower.contains('consumed'))) {
      return 'This request has expired. Please start again.';
    }
    if (lower.contains('not found') || lower.contains('status code of 404')) {
      return 'We could not find what you were looking for.';
    }

    // ── Server failures ─────────────────────────────────────────────
    if (lower.contains('server error') ||
        lower.contains('internal') ||
        lower.contains('status code of 5') ||
        lower.contains('bad gateway') ||
        lower.contains('service unavailable')) {
      return server;
    }

    // ── Strip common technical prefixes ─────────────────────────────
    msg = msg.replaceFirst(
      RegExp(r'^(Exception|Error|AppException|Failure)\s*:\s*'),
      '',
    );

    // ── Anything still technical → generic ──────────────────────────
    final looksTechnical =
        RegExp(
          r'(Exception|Error\b|DioException|subtype|Null check|NoSuchMethod|'
          r'RangeError|FormatException|StateError|TypeError|stack|'
          r'package:|dart:|#\d|\bnull\b|undefined|\{|\}|\[|\]|=>)',
        ).hasMatch(msg) ||
        RegExp(r'[a-z][A-Z][a-z]').hasMatch(msg) || // camelCase field names
        RegExp(r'\b[a-z]+_[a-z_]+\b').hasMatch(msg) || // snake_case codes
        RegExp(r'\b[A-Z]{2,}_[A-Z_]+\b').hasMatch(msg) || // ERROR_CODES
        msg.length > 160;
    if (looksTechnical) return generic;

    // Keep product vocabulary consistent.
    msg = msg
        .replaceAll(RegExp(r'\bLoans\b'), 'Credits')
        .replaceAll(RegExp(r'\bloans\b'), 'credits')
        .replaceAll(RegExp(r'\bLoan\b'), 'Credit')
        .replaceAll(RegExp(r'\bloan\b'), 'credit');

    // Sentence-case and end with a period.
    msg = msg[0].toUpperCase() + msg.substring(1);
    if (!RegExp(r'[.!?]$').hasMatch(msg)) msg = '$msg.';
    return msg;
  }
}
