class UserInfo {
  final String firstName;
  final String lastName;
  final String bvn;
  final String nin;
  final DateTime dateOfBirth;

  UserInfo({
    required this.firstName,
    required this.lastName,
    required this.bvn,
    this.nin = '',
    required this.dateOfBirth,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'bvn': bvn,
        'nin': nin,
        'dateOfBirth': dateOfBirth.toIso8601String(),
      };

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        bvn: json['bvn'] as String,
        nin: json['nin'] as String? ?? '',
        dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      );

  String get maskedBvn {
    if (bvn.length <= 4) return bvn;
    return '${'*' * (bvn.length - 4)}${bvn.substring(bvn.length - 4)}';
  }

  String get maskedNin {
    if (nin.length <= 4) return nin;
    return '${'*' * (nin.length - 4)}${nin.substring(nin.length - 4)}';
  }
}