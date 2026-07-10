// ============================================================================
// lib/model/bills/bills_model.dart
// Data models for the Airtime and Data purchase features.
//
// NETWORK DETECTION:
//   Nigerian phone numbers follow this format: 0[prefix][8-digit-subscriber]
//   All prefixes here are NCC-assigned (Nigerian Communications Commission).
// ============================================================================

// ignore_for_file: avoid_classes_with_only_static_members
import 'package:flutter/material.dart' show Color;

// ---------------------------------------------------------------------------
// NETWORK PROVIDER ENUM
// ---------------------------------------------------------------------------

enum NetworkProvider {
  mtn,
  airtel,
  glo,
  nineMobile,
}

class NetworkInfo {
  final NetworkProvider provider;
  final String name;
  final Color brandColor;

  /// Nigerian number prefixes assigned to this network by the NCC.
  /// Longer prefixes (5 chars) must be checked before 4-char ones.
  final List<String> prefixes;

  const NetworkInfo({
    required this.provider,
    required this.name,
    required this.brandColor,
    required this.prefixes,
  });
}

/// Canonical list of Nigerian mobile networks with NCC-assigned prefixes.
/// Last updated: 2024. Check NCC website for any new prefix allocations.
final List<NetworkInfo> nigeriaMobileNetworks = [
  NetworkInfo(
    provider: NetworkProvider.mtn,
    name: 'MTN',
    brandColor: const Color(0xFFFFCC00),
    prefixes: [
      // 5-digit prefixes (must check first)
      '07025', '07026',
      // 4-digit prefixes
      '0703', '0706', '0803', '0806', '0810', '0813', '0814', '0816',
      '0903', '0906', '0913', '0916',
    ],
  ),
  NetworkInfo(
    provider: NetworkProvider.airtel,
    name: 'Airtel',
    brandColor: const Color(0xFFE3001B),
    prefixes: [
      // 5-digit prefixes
      '07028', '07029',
      // 4-digit prefixes
      '0701', '0708', '0802', '0808', '0812', '0901', '0902', '0904',
      '0907', '0912',
    ],
  ),
  NetworkInfo(
    provider: NetworkProvider.glo,
    name: 'Glo',
    brandColor: const Color(0xFF009A44),
    prefixes: [
      // 5-digit prefixes
      '07057', '07058',
      // 4-digit prefixes
      '0705', '0805', '0807', '0811', '0815', '0905', '0915',
    ],
  ),
  NetworkInfo(
    provider: NetworkProvider.nineMobile,
    name: '9mobile',
    brandColor: const Color(0xFF006633),
    prefixes: [
      '0809',
      '0817',
      '0818',
      '0908',
      '0909',
    ],
  ),
];

// ---------------------------------------------------------------------------
// AIRTIME MODELS
// ---------------------------------------------------------------------------

class AirtimePurchaseRequest {
  final String phoneNumber;
  final NetworkProvider network;
  final double amount;

  const AirtimePurchaseRequest({
    required this.phoneNumber,
    required this.network,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'phone_number': phoneNumber,
        'network': network.name.toUpperCase(),
        'amount': amount,
      };
}

class AirtimePurchaseResponse {
  final bool success;
  final String transactionId;
  final String message;
  final double amount;
  final String phoneNumber;
  final String network;
  final DateTime createdAt;

  const AirtimePurchaseResponse({
    required this.success,
    required this.transactionId,
    required this.message,
    required this.amount,
    required this.phoneNumber,
    required this.network,
    required this.createdAt,
  });

  factory AirtimePurchaseResponse.fromJson(Map<String, dynamic> json) {
    return AirtimePurchaseResponse(
      success: json['success'] ?? false,
      transactionId: json['transaction_id'] ?? json['transactionId'] ?? '',
      message: json['message'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      network: json['network'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

/// Validity buckets for the tab-based data plan selector.
enum DataValidity {
  daily,
  weekly,
  monthly,
  twoMonths,
  threeMonths,
}

class DataPlan {
  /// Unique plan identifier (used as the API payload field).
  final String id;

  /// Short display name shown in the data badge: "1GB", "500MB", etc.
  final String name;

  /// Price in Nigerian Naira (NGN).
  final double price;

  /// Validity bucket — determines which tab this plan appears in.
  final DataValidity validity;

  /// Human-readable validity string: "30 Days", "7 Days", etc.
  final String validityLabel;

  /// Full description shown in plan tiles: "1GB • Valid for 30 Days".
  final String description;

  /// Network this plan belongs to.
  final NetworkProvider network;

  const DataPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.validity,
    required this.validityLabel,
    required this.description,
    required this.network,
  });

  factory DataPlan.fromJson(Map<String, dynamic> json) {
    return DataPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] as num).toDouble(),
      validity: DataValidity.values.firstWhere(
        (v) => v.name == (json['validity'] ?? 'monthly'),
        orElse: () => DataValidity.monthly,
      ),
      validityLabel: json['validity_label'] ?? json['validityLabel'] ?? '',
      description: json['description'] ?? '',
      network: NetworkProvider.values.firstWhere(
        (n) => n.name.toUpperCase() == (json['network'] ?? '').toUpperCase(),
        orElse: () => NetworkProvider.mtn,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'validity': validity.name,
        'validity_label': validityLabel,
        'description': description,
        'network': network.name.toUpperCase(),
      };
}

class DataPurchaseRequest {
  final String phoneNumber;
  final NetworkProvider network;
  final DataPlan plan;

  const DataPurchaseRequest({
    required this.phoneNumber,
    required this.network,
    required this.plan,
  });

  Map<String, dynamic> toJson() => {
        'phone_number': phoneNumber,
        'network': network.name.toUpperCase(),
        'plan_id': plan.id,
        'amount': plan.price,
      };
}

class DataPurchaseResponse {
  final bool success;
  final String transactionId;
  final String message;
  final DataPlan plan;
  final String phoneNumber;
  final String network;
  final DateTime createdAt;

  const DataPurchaseResponse({
    required this.success,
    required this.transactionId,
    required this.message,
    required this.plan,
    required this.phoneNumber,
    required this.network,
    required this.createdAt,
  });

  factory DataPurchaseResponse.fromJson(Map<String, dynamic> json) {
    return DataPurchaseResponse(
      success: json['success'] ?? false,
      transactionId: json['transaction_id'] ?? json['transactionId'] ?? '',
      message: json['message'] ?? '',
      plan: DataPlan.fromJson(json['plan']),
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      network: json['network'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SHARED: RECENT BENEFICIARY
// Used by both Airtime and Data "Select Beneficiary" lists.
// ---------------------------------------------------------------------------

enum BillsType { airtime, data }

class BillsBeneficiary {
  final String id;
  final String name;
  final String phoneNumber;
  final NetworkProvider network;
  final BillsType lastPurchaseType;
  final DateTime lastPurchaseDate;

  const BillsBeneficiary({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.network,
    required this.lastPurchaseType,
    required this.lastPurchaseDate,
  });

  factory BillsBeneficiary.fromJson(Map<String, dynamic> json) {
    return BillsBeneficiary(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      network: NetworkProvider.values.firstWhere(
        (n) => n.name.toUpperCase() == (json['network'] ?? '').toUpperCase(),
        orElse: () => NetworkProvider.mtn,
      ),
      lastPurchaseType: json['last_purchase_type'] == 'data'
          ? BillsType.data
          : BillsType.airtime,
      lastPurchaseDate: DateTime.parse(
        json['last_purchase_date'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone_number': phoneNumber,
        'network': network.name.toUpperCase(),
        'last_purchase_type': lastPurchaseType.name,
        'last_purchase_date': lastPurchaseDate.toIso8601String(),
      };
}
