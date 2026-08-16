// =============================================================================
// lib/mock/mock_api_data.dart
// Kudikit — Centralised mock responses + API base URL
//
// AUDIT RULE: every map passed to a model's fromJson() uses the EXACT key
// strings that fromJson() reads. Mismatches are documented inline with
// "was: <old key>" comments.
//
// Quick reference — what each fromJson reads:
//   UserModel            → userId, email, phoneNumber, name, bvn, nin,
//                          isEmailVerified, isPhoneVerified, isBvnVerified,
//                          isAddressVerified, isSelfieVerified, isDocumentVerified,
//                          createdAt, lastLogin
//   UserVerificationData → first_name, middle_name, last_name, full_name,
//     (both variants)      date_of_birth, phone_number, photo_url, gender,
//                          bvn|nin|id_number, id_type
//   Bank                 → id, name, code, logo (required!), ussd_code, is_active
//   CardTopUpResponse    → success, message, transaction_id?, reference?,
//                          requires_otp, otp_reference?
//   TransactionReceipt   → transaction_type, amount, status, paying_bank,
//                          credited_to, transaction_number, transaction_date
//   AccountDetails       → account_number, account_name, bank_name, reference_code
//   ElectricityAccountDetail → name, meter_number, meter_type, provider, location
//   AirtimePurchaseResponse  → dual-key: transaction_id|transactionId,
//                              phone_number|phoneNumber, created_at|createdAt
//   ElectricityPaymentResponse → dual-key: same pattern as above
//   MoneyRequest         → id, requesterId, requesterName, requesterPhone,
//                          requesterAvatar, amount, reason, category, description,
//                          createdAt, dueDate, isPrivate, status, paidAmount,
//                          paidAt, recipientIds, deliveryMethod
//   NotificationPreferences → transactionSuccess, depositNotification,
//                          withdrawalNotification, largeTransactionAlert,
//                          billPaymentReminder, failedBillPaymentAlert,
//                          rewardEarnedAlert, rewardExpiryAlert, promotionalOffers,
//                          partnerOffers, newFeatureAnnouncements, tutorialPrompt,
//                          feedbackRequest, announcementBanners
//   Transaction          → id, title|description, date, amount, status, type
//   BulkTransferRecipient → id, name, accountType, accountNumber, bankName,
//                           bankCode, phoneNumber, narration, amount, isVerified
// =============================================================================

import 'package:kudipay/model/device/device_metadata.dart';
import 'package:kudipay/config/api_config.dart' show kBaseUrl;

export 'package:kudipay/config/api_config.dart' show kBaseUrl;

String _txId() => 'TXN${DateTime.now().millisecondsSinceEpoch}';
String _mockToken() =>
    'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';

// =============================================================================
// Auth
// =============================================================================
class MockAuthData {
  // Not parsed through fromJson — top-level fields read directly.
  static Map<String, dynamic> registerSuccess({
    required String email,
    required String phoneNumber,
    DeviceMetadata? deviceMetadata,   
  }) =>
      {
        'success': true,
        'userId': 'usr_${DateTime.now().millisecondsSinceEpoch}',
        'message': 'Verification code sent to $email',
        if (deviceMetadata != null) ...deviceMetadata.toJson(),
      };

  static const Map<String, dynamic> registerEmailTaken = {
    'success': false,
    'message': 'An account with this email already exists.',
  };

  // 'user' map → UserModel.fromJson
  static Map<String, dynamic> loginSuccess({
    String email = 'user@example.com', required DeviceMetadata deviceMetadata,
  }) =>
      {
        'success': true,
        'token': _mockToken(),
        'user': {
          'userId': 'usr_001', // was: 'id'
          'email': email,
          'phoneNumber': '+2348012345678', // was: 'phone_number'
          'name': 'Abraham Chidubem',
          'isEmailVerified': true, // was: 'is_email_verified'
          'isPhoneVerified': true,
          'isBvnVerified': true,
          'isAddressVerified': false,
          'isSelfieVerified': true,
          'isDocumentVerified': false,
          'createdAt': '2024-01-15T08:30:00Z', // was: 'created_at'
          'lastLogin': DateTime.now().toIso8601String(), // was: 'last_login'
        },
      };

  static const Map<String, dynamic> loginInvalidCredentials = {
    'success': false,
    'message': 'Invalid email or password.',
  };

  // 'user' map → UserModel.fromJson
  static Map<String, dynamic> verifyEmailSuccess({
    String email = 'user@example.com',
  }) =>
      {
        'success': true,
        'token': _mockToken(),
        'user': {
          'userId': 'usr_001', // was: 'id'
          'email': email,
          'phoneNumber': '+2348012345678', // was: 'phone_number'
          'name': 'Abraham Chidubem',
          'isEmailVerified': true, // was: 'is_email_verified'
          'isPhoneVerified': true,
          'isBvnVerified': true,
          'isAddressVerified': false,
          'isSelfieVerified': true,
          'isDocumentVerified': false,
          'createdAt': '2024-01-15T08:30:00Z', // was: 'created_at'
          'lastLogin': DateTime.now().toIso8601String(), // was: 'last_login'
        },
      };

  static const Map<String, dynamic> tokenValid = {'valid': true};

  // Flat map → UserModel.fromJson (profile endpoint / storage reload)
  static const Map<String, dynamic> userProfile = {
    'userId': 'usr_001', // was: 'id'
    'email': 'dubemkudikit@gmail.com',
    'phoneNumber': '+2348014532643', // was: 'phone_number'
    'name': 'Abraham Chidubem Kudikit',
    'isEmailVerified': true, // was: 'is_email_verified'
    'isPhoneVerified': true, // was: missing
    'isBvnVerified': true, // was: 'is_bvn_verified'
    'isAddressVerified': false, // was: 'is_address_verified'
    'isSelfieVerified': true, // was: 'is_selfie_verified'
    'isDocumentVerified': false, // was: 'is_document_verified'
    'createdAt': '2024-01-15T08:30:00Z', // was: 'created_at'
    'lastLogin': '2024-01-15T08:30:00Z', // was: missing
    // Extra display fields — not read by UserModel.fromJson, harmless:
    'firstName': 'Abraham',
    'middleName': 'Chidubem',
    'lastName': 'Kudikit',
    'dateOfBirth': '1990-05-15',
    'gender': 'Male',
    'address': '15 Victoria Island, Lagos',
    'state': 'Lagos',
    'tier': 1,
    'profilePhotoUrl': null,
  };
}

// =============================================================================
// Wallet — read directly in WalletNotifier, no fromJson.
// Keys accessed: 'balance', 'account_number', 'account_name', 'bank_name'.
// All already correct.
// =============================================================================
class MockWalletData {
  static const Map<String, dynamic> balanceResponse = {
    'balance': 135780.00,
    'currency': 'NGN',
    'last_updated': '2025-03-16T10:00:00Z',
  };

  static const Map<String, dynamic> accountDetailsResponse = {
    'account_number': '8123456789',
    'account_name': 'Abraham Chidubem Kudikit',
    'bank_name': 'Kudikit MFB',
    'bank_code': '090267',
  };
}

// =============================================================================
// Transfer — P2PTransferService builds models directly, never calls fromJson.
// Keys are fine as-is.
// =============================================================================
class MockTransferData {
  static Map<String, dynamic> validateAccountSuccess({
    String accountNumber = '3004749378',
    String name = 'PETER AKINOLA',
    String bankName = 'Guaranty Trust Bank',
  }) =>
      {
        'success': true,
        'account_number': accountNumber,
        'account_name': name,
        'bank_name': bankName,
        'bank_code': '058',
      };

  static const Map<String, dynamic> validateAccountNotFound = {
    'success': false,
    'message': 'Account number not found.',
  };

  static Map<String, dynamic> transferSuccess({
    required double amount,
    String recipientName = 'PETER AKINOLA',
  }) =>
      {
        'success': true,
        'transaction_id': _txId(),
        'transaction_type': 'Transfer',
        'amount': amount,
        'fee': 0.00,
        'paying_bank': 'Kudikit MFB',
        'paying_bank_account': '8123456789',
        'credited_to': 'Guaranty Trust Bank',
        'recipient_name': recipientName,
        'status': 'successful',
        'created_at': DateTime.now().toIso8601String(),
      };

  static const Map<String, dynamic> transferInsufficientFunds = {
    'success': false,
    'message': 'Insufficient balance to complete this transfer.',
  };

  static const Map<String, dynamic> transferInvalidPin = {
    'success': false,
    'message': 'Incorrect transaction PIN.',
  };

  static const Map<String, dynamic> recentContactsResponse = {
    'contacts': [
      {
        'id': '1',
        'name': 'Squad YEM YEM SUPERSTORE LIMITED',
        'account_number': '3004749378',
        'bank_name': 'GTBank',
        'bank_code': '058',
        'last_transfer_date': '2024-12-13T10:00:00Z'
      },
      {
        'id': '2',
        'name': 'John Doe Peters',
        'account_number': '3004749378',
        'bank_name': 'GTBank',
        'bank_code': '058',
        'last_transfer_date': '2024-12-09T14:22:00Z'
      },
      {
        'id': '3',
        'name': 'Amaka Obi',
        'account_number': '8001234567',
        'bank_name': 'Kudikit MFB',
        'bank_code': '090267',
        'last_transfer_date': '2024-12-01T08:10:00Z'
      },
    ],
  };

  static Map<String, dynamic> feeResponse({double amount = 5000}) => {
        'amount': amount,
        'fee': amount <= 5000 ? 10.75 : 26.88,
        'currency': 'NGN',
      };
}

// =============================================================================
// Transactions — items → Transaction.fromJson
// Reads: id, title|description, date, amount, status, type — all correct.
// =============================================================================
class MockTransactionData {
  static const Map<String, dynamic> transactionListResponse = {
    'transactions': [
      {
        'id': 'TXN1704067200000',
        'title': 'Transfer to POS Transfer - TEMI OLUWA',
        'type': 'debit',
        'amount': 10200.00,
        'status': 'successful',
        'category': 'transfer',
        'recipient': 'TEMI OLUWA',
        'note': null,
        'date': '2024-12-20T10:39:25Z',
        'reference': 'REF_1704067200000'
      },
      {
        'id': 'TXN1704010000000',
        'title': 'Airtime - MTN 08012345678',
        'type': 'debit',
        'amount': 500.00,
        'status': 'successful',
        'category': 'airtime',
        'recipient': '08012345678',
        'note': null,
        'date': '2024-12-19T14:05:00Z',
        'reference': 'REF_1704010000000'
      },
      {
        'id': 'TXN1703950000000',
        'title': 'Credit - Bank Transfer',
        'type': 'credit',
        'amount': 50000.00,
        'status': 'successful',
        'category': 'transfer',
        'sender': 'JOHN OKAFOR',
        'note': 'Monthly allowance',
        'date': '2024-12-18T08:00:00Z',
        'reference': 'REF_1703950000000'
      },
      {
        'id': 'TXN1703900000000',
        'title': 'DSTV Premium Subscription',
        'type': 'debit',
        'amount': 24500.00,
        'status': 'successful',
        'category': 'cable_tv',
        'recipient': 'MultiChoice',
        'note': null,
        'date': '2024-12-17T12:30:00Z',
        'reference': 'REF_1703900000000'
      },
      {
        'id': 'TXN1703850000000',
        'title': 'Transfer to GTBank',
        'type': 'debit',
        'amount': 5000.00,
        'status': 'failed',
        'category': 'transfer',
        'recipient': 'AMAKA OBI',
        'note': 'Lunch',
        'date': '2024-12-16T09:15:00Z',
        'reference': 'REF_1703850000000'
      },
    ],
    'total': 5,
    'page': 1,
    'limit': 50,
  };

  static const Map<String, dynamic> downloadResponse = {
    'download_url': 'https://api.Kudikit.com/downloads/statement_2024.pdf',
    'expires_at': '2025-03-17T10:00:00Z',
  };
}

// =============================================================================
// Bills
// =============================================================================
class MockBillsData {
  // AirtimePurchaseResponse.fromJson — dual-key tolerant, snake_case correct.
  static Map<String, dynamic> airtimePurchaseSuccess({
    required String phoneNumber,
    required String network,
    required double amount,
  }) =>
      {
        'success': true,
        'transaction_id': _txId(),
        'message': 'Airtime purchase successful',
        'amount': amount,
        'phone_number': phoneNumber,
        'network': network.toUpperCase(),
        'created_at': DateTime.now().toIso8601String(),
      };

  static const Map<String, dynamic> cableTvBillersResponse = {
    'billers': [
      {'id': 'dstv', 'name': 'DSTV', 'logo_url': null},
      {'id': 'gotv', 'name': 'GOTV', 'logo_url': null},
      {'id': 'starsat', 'name': 'StarSat', 'logo_url': null},
      {'id': 'showmax', 'name': 'Showmax', 'logo_url': null},
    ],
  };

  static const Map<String, dynamic> dstvPackagesResponse = {
    'packages': [
      {
        'id': 'dstv_padi',
        'name': 'Padi',
        'amount': 2950,
        'validity': '30 days'
      },
      {
        'id': 'dstv_compact',
        'name': 'Compact',
        'amount': 15700,
        'validity': '30 days'
      },
      {
        'id': 'dstv_premium',
        'name': 'Premium',
        'amount': 37000,
        'validity': '30 days'
      },
    ],
  };

  static const Map<String, dynamic> gotvPackagesResponse = {
    'packages': [
      {
        'id': 'gotv-smallie',
        'name': 'GOtv Smallie',
        'amount': 1575,
        'validity': '30 days'
      },
      {
        'id': 'gotv-jinja',
        'name': 'GOtv Jinja',
        'amount': 2715,
        'validity': '30 days'
      },
      {
        'id': 'gotv-jolli',
        'name': 'GOtv Jolli',
        'amount': 4115,
        'validity': '30 days'
      },
    ],
  };

  static const Map<String, dynamic> electricityDiscosResponse = {
    'discos': [
      {'id': 'ekedc', 'name': 'Eko Electric (EKEDC)'},
      {'id': 'ikedc', 'name': 'Ikeja Electric (IKEDC)'},
      {'id': 'aedc', 'name': 'Abuja Electric (AEDC)'},
      {'id': 'phedc', 'name': 'Port Harcourt Electric (PHEDC)'},
      {'id': 'bedc', 'name': 'Benin Electric (BEDC)'},
      {'id': 'eedc', 'name': 'Enugu Electric (EEDC)'},
      {'id': 'kedco', 'name': 'Kano Electric (KEDCO)'},
    ],
  };

  // ElectricityAccountDetail.fromJson reads:
  //   name, meter_number, meter_type, provider, location
  static Map<String, dynamic> validateMeterSuccess({
    String meterNumber = '12345678901',
    String customerName = 'Abraham Chidubem',
    String address = '15 Victoria Island, Lagos',
  }) =>
      {
        'success': true,
        'name': customerName, // was: 'customer_name'
        'meter_number': meterNumber,
        'meter_type': 'prepaid', // was: missing
        'provider': 'Eko Electric (EKEDC)', // was: missing
        'location': address, // was: 'address'
        'account_number': 'ECN0012345678',
        'tariff': 'R2',
      };

  // ElectricityPaymentResponse.fromJson — dual-key tolerant, snake_case correct.
  static Map<String, dynamic> electricityPurchaseSuccess({
    required String meterNumber,
    required double amount,
  }) =>
      {
        'success': true,
        'transaction_id': _txId(),
        'token': '4521 8932 7781 2309 4400',
        'units': (amount / 70).toStringAsFixed(2),
        'amount': amount,
        'meter_number': meterNumber,
        'message': 'Electricity purchase successful',
        'created_at': DateTime.now().toIso8601String(),
      };
}

// =============================================================================
// Add Money
// =============================================================================
class MockAddMoneyData {
  // AccountDetails.fromJson — snake_case, already correct.
  static const Map<String, dynamic> virtualAccountResponse = {
    'account_number': '8123456789',
    'account_name': 'Kudikit - Abraham Chidubem',
    'bank_name': 'Providus Bank',
    'bank_code': '101',
    'reference_code': 'KDP123456',
  };

  // Bank.fromJson reads logo as required String — crashes without it.
  // is_active was also absent; added for explicitness.
  static const Map<String, dynamic> banksResponse = {
    'banks': [
      {
        'id': '1',
        'name': 'Guaranty Trust Bank',
        'code': '058',
        'logo': '',
        'ussd_code': '*737*',
        'is_active': true
      },
      {
        'id': '2',
        'name': 'FirstBank of Nigeria',
        'code': '011',
        'logo': '',
        'ussd_code': '*894*',
        'is_active': true
      },
      {
        'id': '3',
        'name': 'Zenith Bank',
        'code': '057',
        'logo': '',
        'ussd_code': '*966*',
        'is_active': true
      },
      {
        'id': '4',
        'name': 'Access Bank',
        'code': '044',
        'logo': '',
        'ussd_code': '*901*',
        'is_active': true
      },
      {
        'id': '5',
        'name': 'United Bank for Africa (UBA)',
        'code': '033',
        'logo': '',
        'ussd_code': '*919*',
        'is_active': true
      },
      {
        'id': '6',
        'name': 'FCMB',
        'code': '214',
        'logo': '',
        'ussd_code': '*329*',
        'is_active': true
      },
      {
        'id': '7',
        'name': 'Wema Bank (ALAT)',
        'code': '035',
        'logo': '',
        'ussd_code': '*945*',
        'is_active': true
      },
      {
        'id': '8',
        'name': 'Sterling Bank',
        'code': '232',
        'logo': '',
        'ussd_code': '*822*',
        'is_active': true
      },
      {
        'id': '9',
        'name': 'Union Bank',
        'code': '032',
        'logo': '',
        'ussd_code': '*826*',
        'is_active': true
      },
      {
        'id': '10',
        'name': 'Fidelity Bank',
        'code': '070',
        'logo': '',
        'ussd_code': '*770*',
        'is_active': true
      },
    ],
  };

  // Read directly in provider — no fromJson.
  static Map<String, dynamic> ussdGenerateResponse({
    required String bankCode,
    required double amount,
    String bankName = 'GTBank',
    String ussdPrefix = '*737*',
  }) =>
      {
        'bank_code': bankCode,
        'bank_name': bankName,
        'ussd_code': '${ussdPrefix}000*7795#',
        'account_number': '8123456789',
        'amount': amount,
        'time_remaining_minutes': 4,
        'time_remaining_seconds': 24,
      };

  // CardTopUpResponse.fromJson — all keys correct.
  static const Map<String, dynamic> cardTopUpInitiateResponse = {
    'success': true,
    'message': 'OTP sent to your registered phone number',
    'requires_otp': true,
    'otp_reference': 'OTP-REF-123456789',
    'masked_card': '534256*******6758',
  };

  // TransactionReceipt.fromJson reads:
  //   transaction_type, amount, status, paying_bank, credited_to,
  //   transaction_number, transaction_date
  static Map<String, dynamic> cardTopUpVerifyOtpResponse({
    double amount = 100.00,
  }) =>
      {
        'transaction_type': 'Add Money - Bank Card',
        'amount': amount,
        'status': 'successful',
        'paying_bank': 'Guaranty Trust Bank (534256*******6758)',
        'credited_to': 'Kudikit wallet',
        'transaction_number': _txId(), // was: 'transaction_id'
        'transaction_date': DateTime.now().toIso8601String(), // ✅
      };

  static const Map<String, dynamic> qrCodeResponse = {
    'qr_code_url': 'https://api.Kudikit.com/qr/8123456789',
    'account_number': '8123456789',
    'expires_at': null,
  };
}

// =============================================================================
// KYC — UserVerificationData.fromJson (both variants) accept snake_case
// via ?? fallbacks. Already correct.
// =============================================================================
class MockKycData {
  static Map<String, dynamic> verifyIdentitySuccess({
    String idNumber = '22234567890',
    String idType = 'BVN',
  }) =>
      {
        'success': true,
        'first_name': 'Abraham',
        'middle_name': 'Chidubem',
        'last_name': 'Kudikit',
        'full_name': 'Abraham Chidubem Kudikit',
        'date_of_birth': '1990-05-15',
        'phone_number': '08012345678',
        'gender': 'Male',
        'photo_url': null,
        'id_number': idNumber,
        'id_type': idType,
      };

  static const Map<String, dynamic> verifyIdentityNotFound = {
    'success': false,
    'message': 'BVN/NIN not found. Please check the number and try again.',
  };

  static const Map<String, dynamic> uploadDocumentSuccess = {
    'success': true,
    'message': 'Document uploaded successfully. Under review.',
    'document_id': 'doc_001',
    'status': 'under_review',
  };

  static const Map<String, dynamic> uploadSelfieSuccess = {
    'success': true,
    'message': 'Selfie submitted for verification.',
    'match_score': 0.97,
    'is_verified': true,
  };

  static const Map<String, dynamic> kycStatusResponse = {
    'bvn_verified': true,
    'nin_verified': true,
    'address_verified': false,
    'selfie_verified': true,
    'document_verified': false,
    'kyc_level': 1,
    'pending_review': false,
  };
}

// =============================================================================
// Requests — requestListResponse items → MoneyRequest.fromJson
//
// MoneyRequest.fromJson reads camelCase with NO fallback — wrong keys crash.
// 'recipientIds' is List<String>.from(json['recipientIds']) — null crashes hard.
// =============================================================================
class MockRequestData {
  // Used directly — no fromJson.
  static Map<String, dynamic> sendRequestSuccess({
    required double amount,
    String recipientName = 'John Doe',
  }) =>
      {
        'success': true,
        'request_id': 'REQ_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
        'recipient_name': recipientName,
        'status': 'pending',
        'message': 'Money request sent successfully.',
        'created_at': DateTime.now().toIso8601String(),
      };

  // MoneyRequest.fromJson
  static const Map<String, dynamic> requestListResponse = {
    'requests': [
      {
        'id': 'REQ_001',
        'requesterId': 'usr_002', // was: 'requester_account' (wrong field)
        'requesterName': 'Abraham Chidubem', // was: 'requester_name'
        'requesterPhone': '+2348123456789', // was: missing
        'requesterAvatar': null, // was: missing
        'amount': 5000.00,
        'reason': 'Lunch money', // was: 'note'
        'category': 'food', // was: missing
        'description': null, // was: missing
        'createdAt': '2024-12-20T10:00:00Z', // was: 'created_at'
        'dueDate': null, // was: missing
        'isPrivate': true, // was: missing
        'status':
            'RequestStatus.pending', // was: 'pending' (enum.toString() mismatch)
        'paidAmount': null, // was: missing
        'paidAt': null, // was: missing
        'recipientIds': ['usr_001'], // was: MISSING (List.from(null) crashes)
        'deliveryMethod': 'DeliveryMethod.inAppNotification', // was: missing
      },
      {
        'id': 'REQ_002',
        'requesterId': 'usr_003',
        'requesterName': 'Amaka Obi', // was: 'requester_name'
        'requesterPhone': '+2348001234567', // was: missing
        'requesterAvatar': null,
        'amount': 15000.00,
        'reason': 'Project contribution', // was: 'note'
        'category': 'business', // was: missing
        'description': null,
        'createdAt': '2024-12-18T14:00:00Z', // was: 'created_at'
        'dueDate': null,
        'isPrivate': true,
        'status':
            'RequestStatus.paid', // was: 'accepted' (enum.toString() mismatch)
        'paidAmount': 15000.00, // was: missing
        'paidAt': '2024-12-19T09:00:00Z', // was: missing
        'recipientIds': ['usr_001'], // was: MISSING (List.from(null) crashes)
        'deliveryMethod': 'DeliveryMethod.inAppNotification',
      },
    ],
  };
}

// =============================================================================
// Notifications — preferencesResponse['preferences'] → NotificationPreferences.fromJson
//
// fromJson reads camelCase with ?? true defaults — no hard crash, but every
// key in the old mock was wrong so all user preferences were silently ignored.
// =============================================================================
class MockNotificationData {
  static const Map<String, dynamic> preferencesResponse = {
    'preferences': {
      'transactionSuccess': true, // was: 'transaction_alerts'
      'depositNotification': true, // was: missing
      'withdrawalNotification': true, // was: missing
      'largeTransactionAlert': true, // was: missing
      'billPaymentReminder': true, // was: 'bill_reminders'
      'failedBillPaymentAlert': true, // was: missing
      'rewardEarnedAlert': true, // was: missing
      'rewardExpiryAlert': true, // was: missing
      'promotionalOffers':
          false, // was: 'promotional_offers' (same value, different key)
      'partnerOffers': false, // was: missing
      'newFeatureAnnouncements': true, // was: missing
      'tutorialPrompt': true, // was: missing
      'feedbackRequest': true, // was: missing
      'announcementBanners': true, // was: missing
    },
  };

  static const Map<String, dynamic> updatePreferencesSuccess = {
    'success': true,
    'message': 'Notification preferences updated.',
  };
}

// =============================================================================
// Email Change — read directly, no fromJson. Already correct.
// =============================================================================
class MockEmailChangeData {
  static Map<String, dynamic> requestOtpSuccess({
    String email = 'm****@example.com', required DeviceMetadata deviceMetadata,
  }) =>
      {
        'success': true,
        'message': 'OTP sent to your current email address.',
        'maskedEmail': email,
      };

  static const Map<String, dynamic> verifyOtpSuccess = {
    'success': true,
    'message': 'OTP verified successfully.',
    'verificationToken': 'email_change_token_abc123',
  };

  static Map<String, dynamic> changeEmailSuccess({
    String newEmail = 'new@example.com',
  }) =>
      {
        'success': true,
        'message': 'Email address updated successfully.',
        'newEmail': newEmail,
      };

  static const Map<String, dynamic> changeEmailTaken = {
    'success': false,
    'message': 'This email address is already associated with another account.',
  };
}

// =============================================================================
// Device Linking — read directly, no fromJson. Already correct.
// =============================================================================
class MockDeviceLinkData {
  static const Map<String, dynamic> requestDeviceLinkSuccess = {
    'success': true,
    'message': 'Verification code sent to your registered email.',
    'session_id': 'session_device_abc123',
  };

  static const Map<String, dynamic> verifyDeviceLinkSuccess = {
    'success': true,
    'message': 'Device linked successfully.',
    'device_id': 'device_001',
    'token': 'new_device_token_xyz',
  };
}

// =============================================================================
// Tier — read directly in tier_provider, no fromJson. Already correct.
// =============================================================================
class MockTierData {
  static const Map<String, dynamic> tierResponse = {
    'current_tier': 2,
    'tier_name': 'Starter',
    'daily_transfer_limit': 200000.00,
    'single_transfer_limit': 100000.00,
    'monthly_transfer_limit': 500000.00,
    'requirements_met': [
      'phone_verified',
      'email_verified',
      'bvn_verified',
      'selfie_verified'
    ],
    'requirements_pending': [
      'address_verified',
    ],
  };

  static const Map<String, dynamic> tierRequirementsResponse = {
    'tiers': [
      {
        'tier': 1,
        'name': 'Starter',
        'requirements': ['phone_verified', 'email_verified'],
        'daily_limit': 50000,
        'single_limit': 20000
      },
      {
        'tier': 2,
        'name': 'Standard',
        'requirements': ['bvn_verified', 'selfie_verified'],
        'daily_limit': 200000,
        'single_limit': 100000
      },
      {
        'tier': 3,
        'name': 'Premium',
        'requirements': [
          'nin_verified',
          'address_verified',
          'document_verified'
        ],
        'daily_limit': 5000000,
        'single_limit': 1000000
      },
    ],
  };
}

// =============================================================================
// Bulk Transfer
// executeBulkSuccess — read directly, checks 'success'/'status'/'message'. Fine.
// validateBulkResponse results — read directly. Fine.
// templatesResponse — BulkTransferTemplate has no fromJson. Read directly. Fine.
//
// NOTE: BulkTransferRecipient.fromJson (if ever called with API data) reads
// camelCase: accountType, accountNumber, bankName, bankCode, phoneNumber,
// isVerified — NOT snake_case.
// =============================================================================
class MockBulkTransferData {
  static const Map<String, dynamic> validateBulkResponse = {
    'success': true,
    'valid_count': 2,
    'invalid_count': 0,
    'total_amount': 110000.00,
    'fee': 53.75,
    'results': [
      {
        'account_number': '0123456789',
        'account_name': 'JOHN DOE',
        'bank_name': 'GTBank',
        'status': 'valid'
      },
      {
        'account_number': '08124608695',
        'account_name': 'JANE SMITH',
        'bank_name': 'Kudikit MFB',
        'status': 'valid'
      },
    ],
  };

  static Map<String, dynamic> executeBulkSuccess({
    double totalAmount = 110000.00,
  }) =>
      {
        'success': true,
        'batch_id': 'BATCH_${DateTime.now().millisecondsSinceEpoch}',
        'total_amount': totalAmount,
        'recipient_count': 2,
        'status': 'processing',
        'message':
            'Bulk transfer initiated. You will be notified when complete.',
        'created_at': DateTime.now().toIso8601String(),
      };

  static const Map<String, dynamic> templatesResponse = {
    'templates': [
      {
        'id': '1',
        'name': 'Monthly Staff Salary',
        'created_at': '2024-11-15T08:00:00Z',
        'use_count': 5,
        'recipient_count': 2,
        'total_amount': 110000.00
      },
      {
        'id': '2',
        'name': 'Vendor Payments',
        'created_at': '2024-12-01T10:00:00Z',
        'use_count': 3,
        'recipient_count': 1,
        'total_amount': 100000.00
      },
    ],
  };
}