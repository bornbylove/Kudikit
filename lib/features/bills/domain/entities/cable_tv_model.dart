// ============================================================================
// lib/model/cable_tv/cable_tv_model.dart
// Data models for Cable TV subscription payment.
// ============================================================================

enum CableTvProvider { dstv, gotv, startimes }

class CableTvProviderInfo {
  final CableTvProvider provider;
  final String name;

  const CableTvProviderInfo({
    required this.provider,
    required this.name,
  });
}

final List<CableTvProviderInfo> cableTvProviders = [
  CableTvProviderInfo(provider: CableTvProvider.dstv, name: 'DSTV'),
  CableTvProviderInfo(provider: CableTvProvider.startimes, name: 'Startimes'),
  CableTvProviderInfo(provider: CableTvProvider.gotv, name: 'GOTV'),
];

class CableTvPlan {
  final String id;
  final String name;
  final double amount;
  final CableTvProvider provider;

  const CableTvPlan({
    required this.id,
    required this.name,
    required this.amount,
    required this.provider,
  });

  factory CableTvPlan.fromJson(Map<String, dynamic> json) {
    return CableTvPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      provider: CableTvProvider.values.firstWhere(
        (p) => p.name.toLowerCase() == (json['provider'] ?? '').toLowerCase(),
        orElse: () => CableTvProvider.dstv,
      ),
    );
  }
}

// Hardcoded DSTV plans matching the design
final List<CableTvPlan> dstvPlans = [
  CableTvPlan(
      id: 'dstv-padi',
      name: 'DSTV Padi',
      amount: 4400,
      provider: CableTvProvider.dstv),
  CableTvPlan(
      id: 'dstv-yanga',
      name: 'DSTV Yanga',
      amount: 6000,
      provider: CableTvProvider.dstv),
  CableTvPlan(
      id: 'dstv-confam',
      name: 'DSTV Confam',
      amount: 11000,
      provider: CableTvProvider.dstv),
  CableTvPlan(
      id: 'dstv-compact',
      name: 'DSTV Compact',
      amount: 19000,
      provider: CableTvProvider.dstv),
  CableTvPlan(
      id: 'dstv-compact-plus',
      name: 'DSTV Compact plus',
      amount: 30000,
      provider: CableTvProvider.dstv),
  CableTvPlan(
      id: 'dstv-premium',
      name: 'DSTV Premium',
      amount: 44500,
      provider: CableTvProvider.dstv),
  CableTvPlan(
      id: 'dstv-yanga-xtraview',
      name: 'DSTV Yanga + Xtraview',
      amount: 10500,
      provider: CableTvProvider.dstv),
  CableTvPlan(
      id: 'dstv-confam-xtraview',
      name: 'DSTV Confam + Xtraview',
      amount: 10500,
      provider: CableTvProvider.dstv),
];

final List<CableTvPlan> gotvPlans = [
  CableTvPlan(
      id: 'gotv-smallie',
      name: 'GOtv Smallie',
      amount: 1575,
      provider: CableTvProvider.gotv),
  CableTvPlan(
      id: 'gotv-jinja',
      name: 'GOtv Jinja',
      amount: 2715,
      provider: CableTvProvider.gotv),
  CableTvPlan(
      id: 'gotv-jolli',
      name: 'GOtv Jolli',
      amount: 4115,
      provider: CableTvProvider.gotv),
  CableTvPlan(
      id: 'gotv-max',
      name: 'GOtv Max',
      amount: 5500,
      provider: CableTvProvider.gotv),
  CableTvPlan(
      id: 'gotv-supa',
      name: 'GOtv Supa',
      amount: 6400,
      provider: CableTvProvider.gotv),
];

final List<CableTvPlan> startimesPlans = [
  CableTvPlan(
      id: 'startimes-nova',
      name: 'Nova',
      amount: 900,
      provider: CableTvProvider.startimes),
  CableTvPlan(
      id: 'startimes-basic',
      name: 'Basic',
      amount: 2200,
      provider: CableTvProvider.startimes),
  CableTvPlan(
      id: 'startimes-smart',
      name: 'Smart',
      amount: 2700,
      provider: CableTvProvider.startimes),
  CableTvPlan(
      id: 'startimes-classic',
      name: 'Classic',
      amount: 3800,
      provider: CableTvProvider.startimes),
  CableTvPlan(
      id: 'startimes-super',
      name: 'Super',
      amount: 5700,
      provider: CableTvProvider.startimes),
];

List<CableTvPlan> getPlansForProvider(CableTvProvider provider) {
  switch (provider) {
    case CableTvProvider.dstv:
      return dstvPlans;
    case CableTvProvider.gotv:
      return gotvPlans;
    case CableTvProvider.startimes:
      return startimesPlans;
  }
}

class CableTvAccountDetail {
  final String name;
  final String decoderNumber;
  final String provider;
  final String currentPlan;
  final bool isExpired;

  const CableTvAccountDetail({
    required this.name,
    required this.decoderNumber,
    required this.provider,
    required this.currentPlan,
    required this.isExpired,
  });

  factory CableTvAccountDetail.fromJson(Map<String, dynamic> json) {
    return CableTvAccountDetail(
      name: json['name'] ?? '',
      decoderNumber: json['decoder_number'] ?? json['decoderNumber'] ?? '',
      provider: json['provider'] ?? '',
      currentPlan: json['current_plan'] ?? json['currentPlan'] ?? '',
      isExpired: (json['status'] ?? '').toString().toLowerCase() == 'expired',
    );
  }
}

class CableTvPaymentRequest {
  final CableTvProvider provider;
  final String iucNumber;
  final CableTvPlan plan;
  final bool autoRenew;

  const CableTvPaymentRequest({
    required this.provider,
    required this.iucNumber,
    required this.plan,
    required this.autoRenew,
  });

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'iuc_number': iucNumber,
        'plan_id': plan.id,
        'amount': plan.amount,
        'auto_renew': autoRenew,
      };
}
