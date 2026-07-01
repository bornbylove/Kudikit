// lib/features/bills/domain/entities/bill_entities.dart
//
// Pure Dart domain entities for all bill payment types.
//
// FIX SUMMARY (vs previous version):
//   • Added BillsBeneficiaryEntity so the domain repository interface no longer
//     leaks BillsBeneficiary (a model-layer type) across the layer boundary.
//   • No other entity classes changed.

// =============================================================================
// Shared
// =============================================================================

/// A processed bill payment result returned after any successful transaction.
class BillPaymentResultEntity {
  final String transactionId;
  final double amount;
  final String phoneNumber;
  final String providerName;
  final DateTime transactionDate;
  final bool isSuccessful;
  final String? token; // electricity token
  final String? units; // electricity units

  const BillPaymentResultEntity({
    required this.transactionId,
    required this.amount,
    required this.phoneNumber,
    required this.providerName,
    required this.transactionDate,
    this.isSuccessful = true,
    this.token,
    this.units,
  });
}

/// A saved beneficiary for any bill payment type.
/// Uses plain [String] for network and lastPurchaseType so the domain layer
/// has no dependency on model-layer enums (NetworkProvider / BillsType).
class BillsBeneficiaryEntity {
  final String id;
  final String name;
  final String phoneNumber;

  /// Network name string, e.g. "mtn", "airtel", "glo", "nineMobile".
  final String network;

  /// "airtime" or "data".
  final String lastPurchaseType;

  final DateTime lastPurchaseDate;

  const BillsBeneficiaryEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.network,
    required this.lastPurchaseType,
    required this.lastPurchaseDate,
  });
}

// =============================================================================
// Airtime
// =============================================================================

class AirtimePurchaseEntity {
  final String phoneNumber;
  final String network;
  final double amount;

  const AirtimePurchaseEntity({
    required this.phoneNumber,
    required this.network,
    required this.amount,
  });
}

// =============================================================================
// Data
// =============================================================================

class DataPlanEntity {
  final String id;
  final String name;
  final double price;
  final String validity;
  final String network;

  const DataPlanEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.validity,
    required this.network,
  });
}

class DataPurchaseEntity {
  final String phoneNumber;
  final DataPlanEntity plan;

  const DataPurchaseEntity({
    required this.phoneNumber,
    required this.plan,
  });
}

// =============================================================================
// Cable TV
// =============================================================================

class CableTvAccountEntity {
  final String name;
  final String decoderNumber;
  final String provider;
  final String currentPlan;
  final bool isExpired;

  const CableTvAccountEntity({
    required this.name,
    required this.decoderNumber,
    required this.provider,
    required this.currentPlan,
    required this.isExpired,
  });
}

// =============================================================================
// Electricity
// =============================================================================

class MeterAccountEntity {
  final String name;
  final String meterNumber;
  final String address;
  final String tariffClass;
  final double minimumAmount;

  const MeterAccountEntity({
    required this.name,
    required this.meterNumber,
    required this.address,
    required this.tariffClass,
    required this.minimumAmount,
  });
}
