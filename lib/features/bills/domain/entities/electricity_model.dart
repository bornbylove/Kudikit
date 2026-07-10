// ============================================================================
// lib/model/electricity/electricity_model.dart
// Data models for the Electricity bill payment feature.
// ============================================================================

enum ElectricityProvider {
  ibadan,
  jos,
  portHarcourt,
  kaduna,
  ikeja,
  eko,
  enugu,
  kano,
  benin,
}

enum MeterType { prepaid, postpaid }

class ElectricityProviderInfo {
  final ElectricityProvider provider;
  final String name;
  final String shortCode;

  const ElectricityProviderInfo({
    required this.provider,
    required this.name,
    required this.shortCode,
  });
}

final List<ElectricityProviderInfo> electricityProviders = [
  ElectricityProviderInfo(
    provider: ElectricityProvider.ibadan,
    name: 'Ibadan Electricity',
    shortCode: 'IBEDC',
  ),
  ElectricityProviderInfo(
    provider: ElectricityProvider.jos,
    name: 'Jos Electricity',
    shortCode: 'JED',
  ),
  ElectricityProviderInfo(
    provider: ElectricityProvider.portHarcourt,
    name: 'Port Harcourt Electricity',
    shortCode: 'PHED',
  ),
  ElectricityProviderInfo(
    provider: ElectricityProvider.kaduna,
    name: 'Kaduna Electricity',
    shortCode: 'KAEDCO',
  ),
  ElectricityProviderInfo(
    provider: ElectricityProvider.ikeja,
    name: 'Ikeja Electricity',
    shortCode: 'IKEDC',
  ),
  ElectricityProviderInfo(
    provider: ElectricityProvider.eko,
    name: 'Eko Electricity',
    shortCode: 'EKEDC',
  ),
  ElectricityProviderInfo(
    provider: ElectricityProvider.enugu,
    name: 'Enugu Electricity',
    shortCode: 'EEDC',
  ),
  ElectricityProviderInfo(
    provider: ElectricityProvider.kano,
    name: 'Kano Electricity',
    shortCode: 'KEDCO',
  ),
  ElectricityProviderInfo(
    provider: ElectricityProvider.benin,
    name: 'Benin Electricity',
    shortCode: 'BEDC',
  ),
];

class ElectricityAccountDetail {
  final String name;
  final String meterNumber;
  final MeterType meterType;
  final String provider;
  final String location;

  const ElectricityAccountDetail({
    required this.name,
    required this.meterNumber,
    required this.meterType,
    required this.provider,
    required this.location,
  });

  factory ElectricityAccountDetail.fromJson(Map<String, dynamic> json) {
    return ElectricityAccountDetail(
      name: json['name'] ?? '',
      meterNumber: json['meter_number'] ?? json['meterNumber'] ?? '',
      meterType: (json['meter_type'] ?? json['meterType'] ?? 'prepaid')
                  .toString()
                  .toLowerCase() ==
              'prepaid'
          ? MeterType.prepaid
          : MeterType.postpaid,
      provider: json['provider'] ?? '',
      location: json['location'] ?? '',
    );
  }
}

class ElectricityPaymentRequest {
  final ElectricityProvider provider;
  final MeterType meterType;
  final String meterNumber;
  final double amount;

  const ElectricityPaymentRequest({
    required this.provider,
    required this.meterType,
    required this.meterNumber,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'meter_type': meterType.name,
        'meter_number': meterNumber,
        'amount': amount,
      };
}

class ElectricityPaymentResponse {
  final bool success;
  final String transactionId;
  final String message;
  final String? token;
  final double amount;
  final String meterNumber;
  final DateTime createdAt;

  const ElectricityPaymentResponse({
    required this.success,
    required this.transactionId,
    required this.message,
    this.token,
    required this.amount,
    required this.meterNumber,
    required this.createdAt,
  });

  factory ElectricityPaymentResponse.fromJson(Map<String, dynamic> json) {
    return ElectricityPaymentResponse(
      success: json['success'] ?? false,
      transactionId: json['transaction_id'] ?? json['transactionId'] ?? '',
      message: json['message'] ?? '',
      token: json['token'],
      amount: (json['amount'] as num).toDouble(),
      meterNumber: json['meter_number'] ?? json['meterNumber'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }
}
