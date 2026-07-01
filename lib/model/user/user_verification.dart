// lib/models/user_verification.dart

class UserVerificationData {
  final String firstName;
  final String middleName;
  final String lastName;
  final String fullName; // "John Doe Smith"
  final DateTime dateOfBirth;
  final String phoneNumber;
  final String? photoUrl;
  final String gender;
  final String BVN; // or NIN

  UserVerificationData({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.fullName,
    required this.dateOfBirth,
    required this.phoneNumber,
    this.photoUrl,
    required this.gender,
    required this.BVN,
  });

  factory UserVerificationData.fromJson(Map<String, dynamic> json) {
    return UserVerificationData(
      firstName: json['first_name'],
      middleName: json['middle_name'] ?? '',
      lastName: json['last_name'],
      fullName: '${json['first_name']} ${json['last_name']}',
      dateOfBirth: DateTime.parse(json['date_of_birth']),
      phoneNumber: json['phone_number'],
      photoUrl: json['photo_url'],
      gender: json['gender'],
      BVN: json['BVN'],
    );
  }
}

enum IdentificationType {
  BVN, // Bank Verification Number (11 digits)
  NIN, // National Identity Number (11 digits)
}
