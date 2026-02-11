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

class OtpVerified extends AuthState {
  final String phone;
  const OtpVerified({required this.phone});

  @override
  List<Object?> get props => [phone];
}

class PersonalDetailsSaved extends AuthState {
  final UserModel user;
  const PersonalDetailsSaved({required this.user});

  @override
  List<Object?> get props => [user];
}

class PanDetailsSaved extends AuthState {
  final UserModel user;
  const PanDetailsSaved({required this.user});

  @override
  List<Object?> get props => [user];
}

class CreditScoreProcessed extends AuthState {
  const CreditScoreProcessed();
}

class Authenticated extends AuthState {
  final UserModel user;
  const Authenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}