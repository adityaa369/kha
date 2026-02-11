import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? pan;
  final String? aadhar;
  final String? gender;
  final String? dob;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.pan,
    this.aadhar,
    this.gender,
    this.dob,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? json['first_name'] ?? '',
      lastName: json['lastName'] ?? json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      pan: json['pan'],
      aadhar: json['aadhar'],
      gender: json['gender'],
      dob: json['dob'],
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.parse(json['created_at'] ?? json['createdAt'])
          : null,
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.parse(json['updated_at'] ?? json['updatedAt'])
          : null,
    );
  }

  // For API insert/update
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'pan': pan,
      'aadhar': aadhar,
      'gender': gender,
      'dob': dob,
    };
  }

  // Full JSON including id (for caching, etc.)
  Map<String, dynamic> toFullJson() {
    return {
      'id': id,
      ...toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? pan,
    String? aadhar,
    String? gender,
    String? dob,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      pan: pan ?? this.pan,
      aadhar: aadhar ?? this.aadhar,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  String get displayName => '$firstName $lastName';

  String get initials {
    if (firstName.isEmpty && lastName.isEmpty) return '';
    if (lastName.isEmpty) return firstName[0].toUpperCase();
    return '${firstName[0]}${lastName[0]}'.toUpperCase();
  }

  bool get isKycComplete =>
      pan != null && pan!.isNotEmpty &&
          aadhar != null && aadhar!.isNotEmpty &&
          dob != null && dob!.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    phone,
    email,
    pan,
    aadhar,
    gender,
    dob,
    createdAt,
    updatedAt,
  ];
}