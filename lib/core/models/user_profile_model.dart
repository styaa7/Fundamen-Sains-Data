import 'user_role.dart';

class UserProfile {
  final String id;
  final UserRole role;
  final String fullName;
  final String identifierNumber; // NIM atau NIDN
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? faculty;
  final String? studyProgram;

  UserProfile({
    required this.id,
    required this.role,
    required this.fullName,
    required this.identifierNumber,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.faculty,
    this.studyProgram,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: UserRole.fromString(json['role'] as String?),
      fullName: json['full_name'] as String? ?? 'Pengguna',
      identifierNumber: json['identifier_number'] as String? ?? '-',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      faculty: json['faculty'] as String?,
      studyProgram: json['study_program'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'full_name': fullName,
      'identifier_number': identifierNumber,
      'email': email,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
    };
  }
}
