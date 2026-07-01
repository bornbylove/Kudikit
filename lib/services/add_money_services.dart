import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kudipay/config/env.dart';
import 'package:kudipay/model/addmoney/addmoney.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';

// ==================== EXCEPTION CLASS ====================

class AddMoneyException implements Exception {
  final String message;
  final int? statusCode;

  AddMoneyException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

// ==================== BASE SERVICE ====================

class AddMoneyService {
  final String baseUrl;
  final String? authToken;
  final http.Client client;

  AddMoneyService({
    required this.baseUrl,
    this.authToken,
    http.Client? client,
  }) : client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  Future<List<AddMoneyOption>> getAddMoneyOptions() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/add-money/options'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map(
                (json) => AddMoneyOption.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw AddMoneyException(
          'Failed to load add money options: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AddMoneyException) rethrow;
      throw AddMoneyException('Network error: ${e.toString()}');
    }
  }

  Future<AccountDetails> getAccountDetails() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/add-money/account-details'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AccountDetails.fromJson(jsonData as Map<String, dynamic>);
      } else {
        throw AddMoneyException(
          'Failed to get account details: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AddMoneyException) rethrow;
      throw AddMoneyException('Network error: ${e.toString()}');
    }
  }

  Future<String> getUssdCode({required String bankCode}) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/add-money/ussd-code'),
        headers: _headers,
        body: json.encode({'bank_code': bankCode}),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['ussd_code'] as String;
      } else {
        throw AddMoneyException(
          'Failed to get USSD code: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AddMoneyException) rethrow;
      throw AddMoneyException('Network error: ${e.toString()}');
    }
  }

  /// Generate QR code for payment
  Future<String> generateQrCode() async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/add-money/generate-qr'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['qr_code_url'] as String;
      } else {
        throw AddMoneyException(
          'Failed to generate QR code: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AddMoneyException) rethrow;
      throw AddMoneyException('Network error: ${e.toString()}');
    }
  }

  Future<AddMoneyResponse> initiateCardTopUp({
    required double amount,
    required String cardToken,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/add-money/card-topup'),
        headers: _headers,
        body: json.encode({
          'amount': amount,
          'card_token': cardToken,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AddMoneyResponse.fromJson(jsonData as Map<String, dynamic>);
      } else {
        throw AddMoneyException(
          'Failed to initiate card top-up: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AddMoneyException) rethrow;
      throw AddMoneyException('Network error: ${e.toString()}');
    }
  }

  Future<List<Bank>> getBanks() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/banks'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((json) => Bank.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw AddMoneyException(
          'Failed to load banks: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AddMoneyException) rethrow;
      throw AddMoneyException('Network error: ${e.toString()}');
    }
  }

  Future<UssdTransferData> generateUssdCode({
    required String bankCode,
    required double amount,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/add-money/ussd/generate'),
        headers: _headers,
        body: json.encode({
          'bank_code': bankCode,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return UssdTransferData(
          bank: Bank.fromJson(jsonData['bank'] as Map<String, dynamic>),
          amount: (jsonData['amount'] as num).toDouble(),
          ussdCode: jsonData['ussd_code'] as String,
          accountNumber: jsonData['account_number'] as String,
          timeRemaining: Duration(
            minutes: jsonData['time_remaining_minutes'] as int? ?? 4,
          ),
        );
      } else {
        throw AddMoneyException(
          'Failed to generate USSD code: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AddMoneyException) rethrow;
      throw AddMoneyException('Network error: ${e.toString()}');
    }
  }

  /// Initiate card top-up with card details
  Future<CardTopUpResponse> initiateCardTopUpWithDetails(
      CardTopUpRequest request) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/add-money/card/initiate'),
        headers: _headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CardTopUpResponse.fromJson(jsonData as Map<String, dynamic>);
      } else {
        throw AddMoneyException(
          'Failed to initiate card top-up: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AddMoneyException) rethrow;
      throw AddMoneyException('Network error: ${e.toString()}');
    }
  }

  Future<TransactionReceipt> verifyCardTopUpOtp({
    required String otpReference,
    required String otp,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/add-money/card/verify-otp'),
        headers: _headers,
        body: json.encode({
          'otp_reference': otpReference,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TransactionReceipt.fromJson(jsonData as Map<String, dynamic>);
      } else {
        throw AddMoneyException(
          'Failed to verify OTP: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AddMoneyException) rethrow;
      throw AddMoneyException('Network error: ${e.toString()}');
    }
  }

  void dispose() {
    client.close();
  }
}

// ==================== MOCK SERVICE ====================

// class MockAddMoneyService extends AddMoneyService {
//   MockAddMoneyService({String baseUrl = '', String? authToken})
//       : super(baseUrl: baseUrl, authToken: authToken);

//   @override
//   Future<List<AddMoneyOption>> getAddMoneyOptions() async {
//     // Simulate network delay
//     await Future.delayed(const Duration(milliseconds: 800));

//     return const [
//       AddMoneyOption(
//         id: '1',
//         title: 'Bank Transfer',
//         subtitle: 'Add money via mobile or internet banking',
//         icon: 'bank',
//         type: AddMoneyType.bankTransfer,
//       ),
//       AddMoneyOption(
//         id: '2',
//         title: 'Cash Deposit',
//         subtitle: 'Fund your account with nearby merchants',
//         icon: 'cash',
//         type: AddMoneyType.cashDeposit,
//       ),
//       AddMoneyOption(
//         id: '3',
//         title: 'Top-up with card or account',
//         subtitle: 'Add money directly from your bank card or account',
//         icon: 'card',
//         type: AddMoneyType.cardTopUp,
//       ),
//       AddMoneyOption(
//         id: '4',
//         title: 'Bank USSD',
//         subtitle: 'With other banks\' USSD code',
//         icon: 'phone',
//         type: AddMoneyType.ussdTransfer,
//       ),
//       AddMoneyOption(
//         id: '5',
//         title: 'Scan my QR code',
//         subtitle: 'Show QR code to any Opay user',
//         icon: 'qr',
//         type: AddMoneyType.qrCode,
//       ),
//     ];
//   }

//   @override
//   Future<AccountDetails> getAccountDetails() async {
//     await Future.delayed(const Duration(milliseconds: 500));
//     final data = MockAddMoneyData.virtualAccountResponse;
//     return AccountDetails(
//       accountNumber: data['account_number'] as String,
//       accountName: data['account_name'] as String,
//       bankName: data['bank_name'] as String,
//       referenceCode: data['reference_code'] as String?,
//     );
//   }

//   @override
//   Future<String> getUssdCode({required String bankCode}) async {
//     await Future.delayed(const Duration(milliseconds: 500));

//     final acctNum = MockAddMoneyData.virtualAccountResponse['account_number'] as String;
//     final ussdCodes = {
//       '058': '*737*0*$acctNum#',  // GTBank
//       '033': '*901*0*$acctNum#',  // UBA
//       '044': '*894*0*$acctNum#',  // Access Bank
//     };
//     return ussdCodes[bankCode] ?? '*737*0*$acctNum#';
//   }

//   @override
//   Future<String> generateQrCode() async {
//     await Future.delayed(const Duration(milliseconds: 800));

//     return MockAddMoneyData.qrCodeResponse['qr_code_url'] as String;
//   }

//   @override
//   Future<AddMoneyResponse> initiateCardTopUp({
//     required double amount,
//     required String cardToken,
//   }) async {
//     await Future.delayed(const Duration(milliseconds: 1000));
//     final acct = MockAddMoneyData.virtualAccountResponse;
//     return AddMoneyResponse(
//       success: true,
//       message: 'Card top-up initiated successfully',
//       accountDetails: AccountDetails(
//         accountNumber: acct['account_number'] as String,
//         accountName: acct['account_name'] as String,
//         bankName: acct['bank_name'] as String,
//       ),
//     );
//   }

//   @override
//   Future<List<Bank>> getBanks() async {
//     await Future.delayed(const Duration(milliseconds: 600));

//     return const [
//       Bank(
//         id: '1',
//         name: 'Guaranty Trust Bank',
//         code: '058',
//         logo: 'gtbank',
//         ussdCode: '*737*',
//       ),
//       Bank(
//         id: '2',
//         name: 'FirstBank of Nigeria',
//         code: '011',
//         logo: 'firstbank',
//         ussdCode: '*894*',
//       ),
//       Bank(
//         id: '3',
//         name: 'Wema Bank',
//         code: '035',
//         logo: 'wema',
//         ussdCode: '*945*',
//       ),
//       Bank(
//         id: '4',
//         name: 'United Bank of Africa',
//         code: '033',
//         logo: 'uba',
//         ussdCode: '*919*',
//       ),
//       Bank(
//         id: '5',
//         name: 'FCMB',
//         code: '214',
//         logo: 'fcmb',
//         ussdCode: '*329*',
//       ),
//       Bank(
//         id: '6',
//         name: 'Sterling Bank',
//         code: '232',
//         logo: 'sterling',
//         ussdCode: '*822*',
//       ),
//       Bank(
//         id: '7',
//         name: 'Parallex Bank',
//         code: '526',
//         logo: 'parallex',
//         ussdCode: '*833*',
//       ),
//       Bank(
//         id: '8',
//         name: 'Globus Bank',
//         code: '103',
//         logo: 'globus',
//         ussdCode: '*989*',
//       ),
//     ];
//   }

//   @override
//   Future<UssdTransferData> generateUssdCode({
//     required String bankCode,
//     required double amount,
//   }) async {
//     await Future.delayed(const Duration(milliseconds: 800));

//     // Find the bank
//     final banks = await getBanks();
//     final bank = banks.firstWhere(
//       (b) => b.code == bankCode,
//       orElse: () => banks.first,
//     );

//     // Generate USSD code
//     final ussdCode = '${bank.ussdCode}000*7795#';

//     return UssdTransferData(
//       bank: bank,
//       amount: amount,
//       ussdCode: ussdCode,
//       accountNumber: MockAddMoneyData.virtualAccountResponse['account_number'] as String,
//       timeRemaining: const Duration(minutes: 4, seconds: 24),
//     );
//   }

//   @override
//   Future<CardTopUpResponse> initiateCardTopUpWithDetails(
//       CardTopUpRequest request) async {
//     await Future.delayed(const Duration(milliseconds: 1200));

//     // Simulate OTP requirement
//     return const CardTopUpResponse(
//       success: true,
//       message: 'OTP sent to your phone',
//       requiresOtp: true,
//       otpReference: 'OTP-REF-123456789',
//     );
//   }

//   @override
//   Future<TransactionReceipt> verifyCardTopUpOtp({
//     required String otpReference,
//     required String otp,
//   }) async {
//     await Future.delayed(const Duration(milliseconds: 1000));

//     // Simulate successful verification
//     return TransactionReceipt(
//       transactionType: 'Add Money - Bank Card',
//       amount: 100.00,
//       status: 'successful',
//       payingBank: 'Guaranty Trust Bank (534256*******6758)',
//       creditedTo: 'Kudikit wallet',
//       transactionNumber: '21354636473882937447493',
//       transactionDate: DateTime.now(),
//     );
//   }
// }
