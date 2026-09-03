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

class AuthenticatedEmailUnverified extends AuthState {
  @override
  final UserModel user;
  const AuthenticatedEmailUnverified({required this.user});
  @override
  List<Object?> get props => [user];
}

class AuthenticatedEmailVerifiedKycIncomplete extends AuthState {
  @override
  final UserModel user;
  const AuthenticatedEmailVerifiedKycIncomplete({required this.user});
  @override
  List<Object?> get props => [user];
}

class AuthenticatedKycComplete extends AuthState {
  @override
  final UserModel user;
  const AuthenticatedKycComplete({required this.user});
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

// Process States (UI transient states shouldn't dictate core routing, 
// but some are necessary to convey loading context if no other Bloc manages it).
// To satisfy the UI without destroying the new state model, we include these but 
// they must not be used as the ultimate route determinant.
class AuthLoading extends AuthState {}

// Optional transient states that UI currently listens to (e.g., inside AuthChoicePage)
// Ideally, these would move to a distinct RegistrationCubit later.
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
