import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_cubit.dart';

// ── States ──────────────────────────────────────────────────────────────────

abstract class EmailVerificationState extends Equatable {
  const EmailVerificationState();
  @override
  List<Object?> get props => [];
}

class EmailVerificationInitial extends EmailVerificationState {}

class EmailVerificationSending extends EmailVerificationState {}

class EmailVerificationSent extends EmailVerificationState {
  final int cooldownSeconds;
  const EmailVerificationSent({this.cooldownSeconds = 60});
  @override
  List<Object?> get props => [cooldownSeconds];
}

class EmailVerificationChecking extends EmailVerificationState {}

class EmailVerified extends EmailVerificationState {}

class EmailVerificationError extends EmailVerificationState {
  final String message;
  const EmailVerificationError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ───────────────────────────────────────────────────────────────────

class EmailVerificationCubit extends Cubit<EmailVerificationState> {
  final AuthCubit _authCubit;
  Timer? _autoCheckTimer;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  int _autoCheckCount = 0;
  static const int _maxAutoChecks = 60; // 5 minutes at 5s interval

  EmailVerificationCubit({required AuthCubit authCubit})
    : _authCubit = authCubit,
      super(EmailVerificationInitial());

  int get cooldownSeconds => _cooldownSeconds;

  /// Send verification email (initial send on page open)
  Future<void> sendVerificationEmail() async {
    emit(EmailVerificationSending());
    try {
      await _authCubit.sendVerificationEmail();
      _startCooldown();
      emit(EmailVerificationSent(cooldownSeconds: _cooldownSeconds));
    } catch (e) {
      String msg = 'Failed to send verification email.';
      final errStr = e.toString();
      if (errStr.contains('too-many-requests')) {
        msg = 'Too many requests. Please wait a few minutes and try again.';
      } else if (errStr.contains('No email address')) {
        msg = 'No email address is attached to your account.';
      }
      emit(EmailVerificationError(msg));
    }
  }

  /// Resend with cooldown enforcement
  Future<void> resendVerificationEmail() async {
    if (_cooldownSeconds > 0) return;
    await sendVerificationEmail();
  }

  /// Manual verification check (user taps "I've verified")
  Future<void> checkVerificationStatus() async {
    emit(EmailVerificationChecking());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final refreshed = FirebaseAuth.instance.currentUser;
        if (refreshed?.emailVerified == true) {
          await _authCubit.syncFirebaseState();
          _stopAutoCheck();
          emit(EmailVerified());
          return;
        }
      }
      // Not verified yet — go back to sent state
      emit(EmailVerificationSent(cooldownSeconds: _cooldownSeconds));
    } catch (e) {
      emit(EmailVerificationSent(cooldownSeconds: _cooldownSeconds));
    }
  }

  /// Start periodic auto-check (every 5 seconds, max 5 minutes)
  void startAutoCheck() {
    _autoCheckCount = 0;
    _autoCheckTimer?.cancel();
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      _autoCheckCount++;
      if (_autoCheckCount > _maxAutoChecks) {
        _stopAutoCheck();
        return;
      }
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        await user.reload();
        final refreshed = FirebaseAuth.instance.currentUser;
        if (refreshed?.emailVerified == true) {
          _stopAutoCheck();
          await _authCubit.syncFirebaseState();
          emit(EmailVerified());
        }
      } catch (_) {
        // Silent — auto-check should not disrupt UI
      }
    });
  }

  void _stopAutoCheck() {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = null;
  }

  void _startCooldown() {
    _cooldownSeconds = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        _cooldownSeconds--;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Future<void> close() {
    _autoCheckTimer?.cancel();
    _cooldownTimer?.cancel();
    return super.close();
  }
}
