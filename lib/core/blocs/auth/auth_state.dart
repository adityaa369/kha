part of 'auth_cubit.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Unauthenticated extends AuthState {}

class OtpSent extends AuthState {
  final String phone;
  const OtpSent({required this.phone});

  @override
  List<Object?> get props => [phone];
}

class PinSetupRequired extends AuthState {}

class Authenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}