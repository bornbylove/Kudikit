import 'package:cloud_firestore/cloud_firestore.dart';

class AgentModel {
  final String id;
  final String shopName;
  final String ownerName;
  final String accountNumber;
  final String bankName;
  final String profileImageUrl;
  final double rating;
  final int totalTransactions;
  final bool isAvailable;
  final double commissionPercent;
  final double availableCash;
  final double minWithdrawal;
  final double maxWithdrawal;
  final String openingTime;
  final String closingTime;
  final String operatingDays;
  final String address;
  final List<String> languages;
  final GeoPoint location;
  final String phoneNumber;
  double? distanceKm;

  AgentModel({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.accountNumber,
    required this.bankName,
    required this.profileImageUrl,
    required this.rating,
    required this.totalTransactions,
    required this.isAvailable,
    required this.commissionPercent,
    required this.availableCash,
    required this.minWithdrawal,
    required this.maxWithdrawal,
    required this.openingTime,
    required this.closingTime,
    required this.operatingDays,
    required this.address,
    required this.languages,
    required this.location,
    required this.phoneNumber,
    this.distanceKm,
  });

  factory AgentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgentModel(
      id: doc.id,
      shopName: data['shopName'] ?? '',
      ownerName: data['ownerName'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      bankName: data['bankName'] ?? 'Kudikit',
      profileImageUrl: data['profileImageUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalTransactions: data['totalTransactions'] ?? 0,
      isAvailable: data['isAvailable'] ?? false,
      commissionPercent: (data['commissionPercent'] ?? 1.5).toDouble(),
      availableCash: (data['availableCash'] ?? 0.0).toDouble(),
      minWithdrawal: (data['minWithdrawal'] ?? 500.0).toDouble(),
      maxWithdrawal: (data['maxWithdrawal'] ?? 500000.0).toDouble(),
      openingTime: data['openingTime'] ?? '8:00am',
      closingTime: data['closingTime'] ?? '8:00pm',
      operatingDays: data['operatingDays'] ?? 'Daily',
      address: data['address'] ?? '',
      languages: List<String>.from(data['languages'] ?? ['English']),
      location: data['location'] as GeoPoint,
      phoneNumber: data['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shopName': shopName,
      'ownerName': ownerName,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
      'totalTransactions': totalTransactions,
      'isAvailable': isAvailable,
      'commissionPercent': commissionPercent,
      'availableCash': availableCash,
      'minWithdrawal': minWithdrawal,
      'maxWithdrawal': maxWithdrawal,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'operatingDays': operatingDays,
      'address': address,
      'languages': languages,
      'location': location,
      'phoneNumber': phoneNumber,
    };
  }

  /// Mock agents for UI testing / development
  static List<AgentModel> mockAgents() {
    return [
      AgentModel(
        id: 'agent_001',
        shopName: "Adeolu's Shop",
        ownerName: 'Adeolu Adeyemi',
        accountNumber: '81234563354',
        bankName: 'Kudikit',
        profileImageUrl: '',
        rating: 4.8,
        totalTransactions: 1250,
        isAvailable: true,
        commissionPercent: 1.5,
        availableCash: 125000,
        minWithdrawal: 500,
        maxWithdrawal: 500000,
        openingTime: '8:00am',
        closingTime: '8:00pm',
        operatingDays: 'Daily',
        address: '12 Admiralty Way, Lekki',
        languages: ['English', 'Igbo', 'Yoruba'],
        location: const GeoPoint(6.4281, 3.4219),
        phoneNumber: '+2348012345678',
        distanceKm: 0.6,
      ),
      AgentModel(
        id: 'agent_002',
        shopName: "Chidi's Store",
        ownerName: 'Chidi Okonkwo',
        accountNumber: '81234563355',
        bankName: 'Kudikit',
        profileImageUrl: '',
        rating: 4.6,
        totalTransactions: 890,
        isAvailable: true,
        commissionPercent: 1.5,
        availableCash: 80000,
        minWithdrawal: 500,
        maxWithdrawal: 300000,
        openingTime: '9:00am',
        closingTime: '7:00pm',
        operatingDays: 'Mon - Sat',
        address: '5 Victoria Island, Lagos',
        languages: ['English', 'Igbo'],
        location: const GeoPoint(6.4270, 3.4230),
        phoneNumber: '+2348023456789',
        distanceKm: 0.8,
      ),
      AgentModel(
        id: 'agent_003',
        shopName: "Fatima's Kiosk",
        ownerName: 'Fatima Bello',
        accountNumber: '81234563356',
        bankName: 'Kudikit',
        profileImageUrl: '',
        rating: 4.9,
        totalTransactions: 2100,
        isAvailable: false,
        commissionPercent: 1.5,
        availableCash: 200000,
        minWithdrawal: 500,
        maxWithdrawal: 500000,
        openingTime: '7:00am',
        closingTime: '9:00pm',
        operatingDays: 'Daily',
        address: '22 Broad Street, Lagos Island',
        languages: ['English', 'Yoruba', 'Hausa'],
        location: const GeoPoint(6.4260, 3.4210),
        phoneNumber: '+2348034567890',
        distanceKm: 1.2,
      ),
    ];
  }
}
