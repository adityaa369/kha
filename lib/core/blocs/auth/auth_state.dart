part of 'auth_cubit.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  UserModel? get user => null;

  @override
  List<Object?> get props => [];
}

// Bootstrapping Phase
class AuthInitial extends AuthState {}

// Authoritative Backend States
class Unauthenticated extends AuthState {}

class Authenticated extends AuthState {
  @override
  final UserModel user;
  const Authenticated({required this.user});
  @override
  List<Object?> get props => [user];
}

// Special Authorization States
class PasswordResetRequired extends AuthState {
  @override
  final UserModel? user;
  const PasswordResetRequired({this.user});
  @override
  List<Object?> get props => [user];
}

class AuthOffline extends AuthState {
  @override
  final UserModel user;
  const AuthOffline({required this.user});
  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthLoading extends AuthState {}

class OtpSent extends AuthState {
  final String phone;
  const OtpSent({required this.phone});
  @override
  List<Object?> get props => [phone];
}

class OtpVerifying extends AuthState {}

class RegistrationOtpSent extends AuthState {
  final String phone;
  const RegistrationOtpSent({required this.phone});
  @override
  List<Object?> get props => [phone];
}
