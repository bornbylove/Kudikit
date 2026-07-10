// ============================================================================
// lib/services/bill_service.dart
//
// Handles all Airtime & Data purchase API calls for KudiPay.
//
// ─── BACKEND INTEGRATION GUIDE ─────────────────────────────────────────────
// Recommended Nigerian VTU (Virtual Top-Up) providers:
//
//  1. VTpass       → https://vtpass.com/documentation
//     Most widely used. Supports all 4 networks.
//     Auth: API key in header. Service IDs: "mtn", "airtel", "glo", "etisalat"
//
//  2. Flutterwave Bills API → https://developer.flutterwave.com/docs
//     POST https://api.flutterwave.com/v3/bills
//     { country:"NG", customer:"0803...", amount:500, type:"AIRTIME",
//       recurrence:"ONCE", reference:"KD123..." }
//
//  3. Paystack → https://paystack.com/docs/bills-payments
//     Similar structure to Flutterwave.
//
//  4. Nellobytes / Clubkonnect / SmileRecharge (cheaper wholesale VTU rates)
//
// FIX SUMMARY (vs previous version):
//   • buyAirtime() and getDataPlans() and buyData() previously called
//     themselves recursively, causing a StackOverflowError on every invocation.
//     They now delegate to _mockBuy* / _mockGetDataPlans until the real
//     backend endpoints are wired in.
//   • Raw http.Client dependency removed. BillsService now accepts DioClient,
//     so every request automatically carries the Bearer token, the offline
//     guard, and unified error mapping — consistent with all other services.
//   • authToken constructor param removed (token is injected by DioClient's
//     _AuthInterceptor, so a stale token at construction time is no longer
//     a risk).
//   • _generateRequestId() is now used in mock responses so it is not dead
//     code when the real implementation is wired in.
// ============================================================================

import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/features/bills/domain/entities/bill_model.dart';

// ============================================================================
// BillsException
// ============================================================================

class BillsException implements Exception {
  final String message;
  final int? statusCode;

  BillsException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

// ============================================================================
// BillsService
// ============================================================================

class BillsService {
  // FIX: Accept DioClient instead of raw http.Client + authToken string.
  // This ensures every request goes through the auth interceptor, offline
  // guard, and unified error mapping defined in DioClient.
  // ignore: unused_field
  final DioClient _client;

  const BillsService(this._client);

  // ---------------------------------------------------------------------------
  // NETWORK DETECTION
  //
  // Detects the Nigerian mobile network from a phone number.
  // Handles: +234xxx, 234xxx, 0xxx formats.
  // Checks 5-char prefixes before 4-char to avoid false matches.
  // ---------------------------------------------------------------------------

  NetworkProvider? detectNetwork(String phoneNumber) {
    String normalized = phoneNumber.replaceAll(' ', '').replaceAll('-', '');

    // Normalize to local 0xxx format
    if (normalized.startsWith('+234') && normalized.length >= 4) {
      normalized = '0${normalized.substring(4)}';
    } else if (normalized.startsWith('234') && normalized.length >= 4) {
      normalized = '0${normalized.substring(3)}';
    }

    if (normalized.length < 4) return null;

    // Check longer prefixes first (avoids e.g. 0703 matching before 07031)
    for (final network in nigeriaMobileNetworks) {
      for (final prefix in network.prefixes.where((p) => p.length == 5)) {
        if (normalized.startsWith(prefix)) return network.provider;
      }
    }
    for (final network in nigeriaMobileNetworks) {
      for (final prefix in network.prefixes.where((p) => p.length == 4)) {
        if (normalized.startsWith(prefix)) return network.provider;
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // AIRTIME PURCHASE
  //
  // Real endpoint (wire when backend is ready):
  //   POST /bills/airtime
  //   Body: { phone_number, network, amount, request_id }
  //
  // VTpass equivalent:
  //   POST https://vtpass.com/api/pay
  //   { serviceID, phone, amount, request_id }
  // ---------------------------------------------------------------------------

  Future<AirtimePurchaseResponse> buyAirtime(
      AirtimePurchaseRequest request) async {
    // ── TODO: replace mock with real call when backend is ready ─────────────
    // final response = await _client.post<Map<String, dynamic>>(
    //   '/bills/airtime',
    //   data: {
    //     ...request.toJson(),
    //     'request_id': _generateRequestId(),
    //   },
    // );
    // return AirtimePurchaseResponse.fromJson(response.data!);
    return _mockBuyAirtime(request);
  }

  Future<AirtimePurchaseResponse> _mockBuyAirtime(
      AirtimePurchaseRequest request) async {
    await Future.delayed(const Duration(seconds: 2));
    return AirtimePurchaseResponse(
      success: true,
      transactionId: _generateRequestId(),
      message: 'Airtime purchase successful',
      amount: request.amount,
      phoneNumber: request.phoneNumber,
      network: request.network.name.toUpperCase(),
      createdAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // DATA PLANS
  //
  // Real endpoint (wire when backend is ready):
  //   GET /bills/data/plans?network=MTN
  //   Response: { "plans": [ { id, name, price, validity, ... }, ... ] }
  //
  // NOTE: Plans are loaded fresh when the user selects a network on
  // DataPhoneScreen. The mock below contains realistic 2024 Nigerian carrier
  // plan catalogues.
  // ---------------------------------------------------------------------------

  Future<List<DataPlan>> getDataPlans(NetworkProvider network) async {
    // ── TODO: replace mock with real call when backend is ready ─────────────
    // final response = await _client.get<Map<String, dynamic>>(
    //   '/bills/data/plans',
    //   queryParameters: {'network': getNetworkServiceId(network)},
    // );
    // final List<dynamic> raw = response.data!['plans'] as List;
    // return raw.map((p) => DataPlan.fromJson(p as Map<String, dynamic>)).toList();
    return _mockGetDataPlans(network);
  }

  Future<List<DataPlan>> _mockGetDataPlans(NetworkProvider network) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final Map<NetworkProvider, List<DataPlan>> catalogue = {
      // ── MTN Nigeria ──────────────────────────────────────────────────────
      NetworkProvider.mtn: [
        DataPlan(
            id: 'mtn_100mb_1d',
            name: '100MB',
            price: 100,
            validity: DataValidity.daily,
            validityLabel: '1 Day',
            description: '100MB • Valid for 1 Day',
            network: NetworkProvider.mtn),
        DataPlan(
            id: 'mtn_200mb_3d',
            name: '200MB',
            price: 200,
            validity: DataValidity.daily,
            validityLabel: '3 Days',
            description: '200MB • Valid for 3 Days',
            network: NetworkProvider.mtn),
        DataPlan(
            id: 'mtn_500mb_7d',
            name: '500MB',
            price: 300,
            validity: DataValidity.weekly,
            validityLabel: '7 Days',
            description: '500MB • Valid for 7 Days',
            network: NetworkProvider.mtn),
        DataPlan(
            id: 'mtn_1gb_7d',
            name: '1GB',
            price: 500,
            validity: DataValidity.weekly,
            validityLabel: '7 Days',
            description: '1GB • Valid for 7 Days',
            network: NetworkProvider.mtn),
        DataPlan(
            id: 'mtn_1gb_30d',
            name: '1GB',
            price: 1000,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '1GB • Valid for 30 Days',
            network: NetworkProvider.mtn),
        DataPlan(
            id: 'mtn_2gb_30d',
            name: '2GB',
            price: 1500,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '2GB • Valid for 30 Days',
            network: NetworkProvider.mtn),
        DataPlan(
            id: 'mtn_3gb_30d',
            name: '3GB',
            price: 2000,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '3GB • Valid for 30 Days',
            network: NetworkProvider.mtn),
        DataPlan(
            id: 'mtn_5gb_30d',
            name: '5GB',
            price: 3000,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '5GB • Valid for 30 Days',
            network: NetworkProvider.mtn),
        DataPlan(
            id: 'mtn_10gb_30d',
            name: '10GB',
            price: 5000,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '10GB • Valid for 30 Days',
            network: NetworkProvider.mtn),
        DataPlan(
            id: 'mtn_20gb_30d',
            name: '20GB',
            price: 8000,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '20GB • Valid for 30 Days',
            network: NetworkProvider.mtn),
      ],

      // ── Airtel Nigeria ───────────────────────────────────────────────────
      NetworkProvider.airtel: [
        DataPlan(
            id: 'airtl_100mb_1d',
            name: '100MB',
            price: 100,
            validity: DataValidity.daily,
            validityLabel: '1 Day',
            description: '100MB • Valid for 1 Day',
            network: NetworkProvider.airtel),
        DataPlan(
            id: 'airtl_200mb_3d',
            name: '200MB',
            price: 200,
            validity: DataValidity.daily,
            validityLabel: '3 Days',
            description: '200MB • Valid for 3 Days',
            network: NetworkProvider.airtel),
        DataPlan(
            id: 'airtl_300mb_7d',
            name: '300MB',
            price: 300,
            validity: DataValidity.weekly,
            validityLabel: '7 Days',
            description: '300MB • Valid for 7 Days',
            network: NetworkProvider.airtel),
        DataPlan(
            id: 'airtl_750mb_14d',
            name: '750MB',
            price: 500,
            validity: DataValidity.weekly,
            validityLabel: '14 Days',
            description: '750MB • Valid for 14 Days',
            network: NetworkProvider.airtel),
        DataPlan(
            id: 'airtl_1_5gb_30d',
            name: '1.5GB',
            price: 1000,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '1.5GB • Valid for 30 Days',
            network: NetworkProvider.airtel),
        DataPlan(
            id: 'airtl_3gb_30d',
            name: '3GB',
            price: 1500,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '3GB • Valid for 30 Days',
            network: NetworkProvider.airtel),
        DataPlan(
            id: 'airtl_6gb_30d',
            name: '6GB',
            price: 2500,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '6GB • Valid for 30 Days',
            network: NetworkProvider.airtel),
        DataPlan(
            id: 'airtl_10gb_30d',
            name: '10GB',
            price: 3500,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '10GB • Valid for 30 Days',
            network: NetworkProvider.airtel),
        DataPlan(
            id: 'airtl_15gb_30d',
            name: '15GB',
            price: 4000,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '15GB • Valid for 30 Days',
            network: NetworkProvider.airtel),
      ],

      // ── Glo Nigeria ──────────────────────────────────────────────────────
      NetworkProvider.glo: [
        DataPlan(
            id: 'glo_50mb_1d',
            name: '50MB',
            price: 50,
            validity: DataValidity.daily,
            validityLabel: '1 Day',
            description: '50MB • Valid for 1 Day',
            network: NetworkProvider.glo),
        DataPlan(
            id: 'glo_200mb_3d',
            name: '200MB',
            price: 200,
            validity: DataValidity.daily,
            validityLabel: '3 Days',
            description: '200MB • Valid for 3 Days',
            network: NetworkProvider.glo),
        DataPlan(
            id: 'glo_500mb_7d',
            name: '500MB',
            price: 350,
            validity: DataValidity.weekly,
            validityLabel: '7 Days',
            description: '500MB • Valid for 7 Days',
            network: NetworkProvider.glo),
        DataPlan(
            id: 'glo_1gb_7d',
            name: '1GB',
            price: 500,
            validity: DataValidity.weekly,
            validityLabel: '7 Days',
            description: '1GB • Valid for 7 Days',
            network: NetworkProvider.glo),
        DataPlan(
            id: 'glo_1gb_30d',
            name: '1GB',
            price: 1000,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '1GB • Valid for 30 Days',
            network: NetworkProvider.glo),
        DataPlan(
            id: 'glo_2gb_30d',
            name: '2GB',
            price: 1500,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '2GB • Valid for 30 Days',
            network: NetworkProvider.glo),
        DataPlan(
            id: 'glo_4gb_30d',
            name: '4GB',
            price: 2000,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '4GB • Valid for 30 Days',
            network: NetworkProvider.glo),
        DataPlan(
            id: 'glo_7_5gb_30d',
            name: '7.5GB',
            price: 3000,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '7.5GB • Valid for 30 Days',
            network: NetworkProvider.glo),
        DataPlan(
            id: 'glo_10gb_30d',
            name: '10GB',
            price: 4000,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '10GB • Valid for 30 Days',
            network: NetworkProvider.glo),
      ],

      // ── 9mobile Nigeria ──────────────────────────────────────────────────
      NetworkProvider.nineMobile: [
        DataPlan(
            id: '9mob_150mb_7d',
            name: '150MB',
            price: 200,
            validity: DataValidity.weekly,
            validityLabel: '7 Days',
            description: '150MB • Valid for 7 Days',
            network: NetworkProvider.nineMobile),
        DataPlan(
            id: '9mob_400mb_14d',
            name: '400MB',
            price: 400,
            validity: DataValidity.weekly,
            validityLabel: '14 Days',
            description: '400MB • Valid for 14 Days',
            network: NetworkProvider.nineMobile),
        DataPlan(
            id: '9mob_500mb_30d',
            name: '500MB',
            price: 500,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '500MB • Valid for 30 Days',
            network: NetworkProvider.nineMobile),
        DataPlan(
            id: '9mob_1gb_30d',
            name: '1GB',
            price: 1000,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '1GB • Valid for 30 Days',
            network: NetworkProvider.nineMobile),
        DataPlan(
            id: '9mob_1_5gb_30d',
            name: '1.5GB',
            price: 1200,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '1.5GB • Valid for 30 Days',
            network: NetworkProvider.nineMobile),
        DataPlan(
            id: '9mob_2_5gb_30d',
            name: '2.5GB',
            price: 2000,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '2.5GB • Valid for 30 Days',
            network: NetworkProvider.nineMobile),
        DataPlan(
            id: '9mob_5gb_30d',
            name: '5GB',
            price: 3500,
            validity: DataValidity.monthly,
            validityLabel: '30 Days',
            description: '5GB • Valid for 30 Days',
            network: NetworkProvider.nineMobile),
      ],
    };

    return catalogue[network] ?? [];
  }

  // ---------------------------------------------------------------------------
  // DATA PURCHASE
  //
  // Real endpoint (wire when backend is ready):
  //   POST /bills/data
  //   Body: { phone_number, network, plan_id, amount, request_id }
  // ---------------------------------------------------------------------------

  Future<DataPurchaseResponse> buyData(DataPurchaseRequest request) async {
    // ── TODO: replace mock with real call when backend is ready ─────────────
    // final response = await _client.post<Map<String, dynamic>>(
    //   '/bills/data',
    //   data: {
    //     ...request.toJson(),
    //     'request_id': _generateRequestId(),
    //   },
    // );
    // return DataPurchaseResponse.fromJson(response.data!);
    return _mockBuyData(request);
  }

  Future<DataPurchaseResponse> _mockBuyData(DataPurchaseRequest request) async {
    await Future.delayed(const Duration(seconds: 2));
    return DataPurchaseResponse(
      success: true,
      transactionId: _generateRequestId(),
      message: 'Data purchase successful',
      plan: request.plan,
      phoneNumber: request.phoneNumber,
      network: request.network.name.toUpperCase(),
      createdAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // BENEFICIARIES
  //
  // Real endpoints (wire when backend is ready):
  //   GET  /bills/beneficiaries
  //   POST /bills/beneficiaries
  // ---------------------------------------------------------------------------

  Future<List<BillsBeneficiary>> getBeneficiaries() async {
    // ── TODO: replace mock with real call when backend is ready ─────────────
    // final response = await _client.get<Map<String, dynamic>>('/bills/beneficiaries');
    // final List<dynamic> raw = response.data!['beneficiaries'] as List;
    // return raw.map((b) => BillsBeneficiary.fromJson(b as Map<String, dynamic>)).toList();
    return _mockGetBeneficiaries();
  }

  Future<List<BillsBeneficiary>> _mockGetBeneficiaries() async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Empty by default — real beneficiaries are persisted after each transaction.
    return [];
  }

  Future<bool> saveBeneficiary({
    required String name,
    required String phoneNumber,
    required NetworkProvider network,
    required BillsType type,
  }) async {
    // ── TODO: replace mock with real call when backend is ready ─────────────
    // await _client.post('/bills/beneficiaries', data: {
    //   'name': name,
    //   'phone_number': phoneNumber,
    //   'network': getNetworkServiceId(network),
    //   'type': type.name,
    // });
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  /// Maps NetworkProvider to the service ID string expected by your VTU provider.
  /// Update this map to match your chosen provider's documentation.
  String getNetworkServiceId(NetworkProvider network) {
    switch (network) {
      case NetworkProvider.mtn:
        return 'mtn';
      case NetworkProvider.airtel:
        return 'airtel';
      case NetworkProvider.glo:
        return 'glo';
      case NetworkProvider.nineMobile:
        return '9mobile';
    }
  }

  /// Generates a unique idempotency key for each transaction request.
  /// Format: KD + timestamp. Replace with UUID v4 in production.
  String _generateRequestId() => 'KD${DateTime.now().millisecondsSinceEpoch}';
}
