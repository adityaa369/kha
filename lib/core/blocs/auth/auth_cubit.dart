import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    // TODO: Check secure storage for token
    await Future.delayed(const Duration(seconds: 2));
    emit(Unauthenticated());
  }

  Future<void> sendOtp(String phone) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(seconds: 1));
    emit(OtpSent(phone: phone));
  }

  Future<void> verifyOtp(String otp) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(seconds: 1));
    if (otp == '000000') {
      emit(const AuthError('Invalid OTP'));
      emit(OtpSent(phone: '9876543210')); // Return to OTP state
    } else {
      emit(PinSetupRequired());
    }
  }

  Future<void> completeProfile() async {
    emit(AuthLoading());
    await Future.delayed(const Duration(seconds: 1));
    emit(Authenticated());
  }
}
