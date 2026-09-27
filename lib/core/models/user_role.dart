enum UserRole {
  mahasiswa,
  dosen,
  admin;

  static UserRole fromString(String? roleStr) {
    switch (roleStr?.toLowerCase()) {
      case 'dosen':
        return UserRole.dosen;
      case 'admin':
        return UserRole.admin;
      case 'mahasiswa':
      default:
        return UserRole.mahasiswa;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.mahasiswa:
        return 'Mahasiswa';
      case UserRole.dosen:
        return 'Dosen Pembimbing';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}
