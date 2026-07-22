import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/model/device/device_metadata.dart';
import 'package:kudipay/core/utils/device/device_utility.dart';
// ==================== DEVICE LINKING MODELS ====================

enum VerificationMethod {
  email,
  oldDevice,
}

class DeviceLinkingData {
  final String? email;
  final String? maskedEmail;
  final String? oldDeviceName;
  final String? verificationCode;
  final bool isCodeSent;
  final bool isVerified;
  final DateTime? codeSentAt;

  const DeviceLinkingData({
    this.email,
    this.maskedEmail,
    this.oldDeviceName,
    this.verificationCode,
    this.isCodeSent = false,
    this.isVerified = false,
    this.codeSentAt,
  });

  DeviceLinkingData copyWith({
    String? email,
    String? maskedEmail,
    String? oldDeviceName,
    String? verificationCode,
    bool? isCodeSent,
    bool? isVerified,
    DateTime? codeSentAt,
  }) {
    return DeviceLinkingData(
      email: email ?? this.email,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      oldDeviceName: oldDeviceName ?? this.oldDeviceName,
      verificationCode: verificationCode ?? this.verificationCode,
      isCodeSent: isCodeSent ?? this.isCodeSent,
      isVerified: isVerified ?? this.isVerified,
      codeSentAt: codeSentAt ?? this.codeSentAt,
    );
  }
}

class DataSyncSelection {
  final bool savedBeneficiary;
  final bool recentTransactions;
  final bool appPreferences;

  const DataSyncSelection({
    this.savedBeneficiary = true,
    this.recentTransactions = true,
    this.appPreferences = false,
  });

  DataSyncSelection copyWith({
    bool? savedBeneficiary,
    bool? recentTransactions,
    bool? appPreferences,
  }) {
    return DataSyncSelection(
      savedBeneficiary: savedBeneficiary ?? this.savedBeneficiary,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      appPreferences: appPreferences ?? this.appPreferences,
    );
  }
}

// ==================== STATE ====================

class DeviceLinkingState {
  final DeviceLinkingData? data;
  final DataSyncSelection syncSelection;
  final VerificationMethod selectedMethod;
  final bool isLoading;
  final bool isSendingCode;
  final bool isVerifyingCode;
  final bool isSyncing;
  final String? error;
  final String? successMessage;

  const DeviceLinkingState({
    this.data,
    this.syncSelection = const DataSyncSelection(),
    this.selectedMethod = VerificationMethod.email,
    this.isLoading = false,
    this.isSendingCode = false,
    this.isVerifyingCode = false,
    this.isSyncing = false,
    this.error,
    this.successMessage,
  });

  DeviceLinkingState copyWith({
    DeviceLinkingData? data,
    DataSyncSelection? syncSelection,
    VerificationMethod? selectedMethod,
    bool? isLoading,
    bool? isSendingCode,
    bool? isVerifyingCode,
    bool? isSyncing,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return DeviceLinkingState(
      data: data ?? this.data,
      syncSelection: syncSelection ?? this.syncSelection,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      isLoading: isLoading ?? this.isLoading,
      isSendingCode: isSendingCode ?? this.isSendingCode,
      isVerifyingCode: isVerifyingCode ?? this.isVerifyingCode,
      isSyncing: isSyncing ?? this.isSyncing,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ==================== SERVICE ====================

class DeviceLinkingException implements Exception {
  final String message;
  final int? statusCode;

  DeviceLinkingException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class DeviceLinkingService {
  final String baseUrl;
  final String? authToken;

  DeviceLinkingService({
    required this.baseUrl,
    this.authToken,
  });

  Future<DeviceLinkingData> getUserDeviceInfo() async {
    return _mockGetUserDeviceInfo();
  }

  // UPDATED: Now accepts DeviceMetadata so the backend can render the
  // security email template (Image 1) with device/IP/location context.
  // This is the most important trigger for Image 1 — the user is explicitly
  // authorizing a new device, so showing location/IP in the email is critical.
  Future<bool> sendVerificationCode(
    String email,
    VerificationMethod method,
    DeviceMetadata deviceMetadata, // NEW
  ) async {
    return _mockSendVerificationCode(email, method, deviceMetadata);
  }

  Future<bool> verifyCode(String code) async {
    return _mockVerifyCode(code);
  }

  Future<bool> syncData(DataSyncSelection selection) async {
    return _mockSyncData(selection);
  }

  // Mock implementations
  Future<DeviceLinkingData> _mockGetUserDeviceInfo() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const DeviceLinkingData(
      email: 'user@example.com',
      maskedEmail: 'u***8@gmail.com',
      oldDeviceName: 'iPhone 14 Pro',
    );
  }

  Future<bool> _mockSendVerificationCode(
    String email,
    VerificationMethod method,
    DeviceMetadata
        deviceMetadata, // NEW — passed through to real endpoint later
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    // TODO (real call): POST $baseUrl/device/send-verification-code with:
    //   { 'email': email, 'method': method.name, ...deviceMetadata.toJson() }
    // The backend uses device_metadata to populate the security email template.
    return true;
  }

  Future<bool> _mockVerifyCode(String code) async {
    await Future.delayed(const Duration(seconds: 2));
    return code.length == 6;
  }

  Future<bool> _mockSyncData(DataSyncSelection selection) async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }
}

// ==================== NOTIFIER ====================

class DeviceLinkingNotifier extends StateNotifier<DeviceLinkingState> {
  final DeviceLinkingService _service;

  DeviceLinkingNotifier(this._service) : super(const DeviceLinkingState());

  Future<void> loadUserDeviceInfo() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final data = await _service.getUserDeviceInfo();
      state = state.copyWith(
        data: data,
        isLoading: false,
      );
    } on SocketException {
      state = state.copyWith(
        isLoading: false,
        error: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load device information.',
      );
    }
  }

  void selectVerificationMethod(VerificationMethod method) {
    state = state.copyWith(selectedMethod: method);
  }

  Future<void> sendVerificationCode() async {
    if (state.data?.email == null) {
      state = state.copyWith(error: 'Email not found');
      return;
    }

    state = state.copyWith(isSendingCode: true, clearError: true);

    try {
      // Collect device metadata concurrently with the loading state update.
      // This is the primary trigger for the security OTP email (Image 1) —
      // the user is authorising a brand-new device, so device/IP/location
      // context is essential.
      final deviceMetadata = await DeviceInfoService.collect();

      await _service.sendVerificationCode(
        state.data!.email!,
        state.selectedMethod,
        deviceMetadata, // NEW — forwarded to the service / API call
      );

      state = state.copyWith(
        isSendingCode: false,
        data: state.data?.copyWith(
          isCodeSent: true,
          codeSentAt: DateTime.now(),
        ),
        successMessage: 'Verification code sent successfully',
      );
    } on SocketException {
      state = state.copyWith(
        isSendingCode: false,
        error: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      state = state.copyWith(
        isSendingCode: false,
        error: 'Failed to send verification code.',
      );
    }
  }

  Future<bool> verifyCode(String code) async {
    state = state.copyWith(isVerifyingCode: true, clearError: true);

    try {
      final isValid = await _service.verifyCode(code);

      if (isValid) {
        state = state.copyWith(
          isVerifyingCode: false,
          data: state.data?.copyWith(
            verificationCode: code,
            isVerified: true,
          ),
        );
        return true;
      } else {
        state = state.copyWith(
          isVerifyingCode: false,
          error: 'Invalid verification code',
        );
        return false;
      }
    } on SocketException {
      state = state.copyWith(
        isVerifyingCode: false,
        error: 'No internet connection. Please check your network.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isVerifyingCode: false,
        error: 'Verification failed. Please try again.',
      );
      return false;
    }
  }

  void updateSyncSelection({
    bool? savedBeneficiary,
    bool? recentTransactions,
    bool? appPreferences,
  }) {
    state = state.copyWith(
      syncSelection: state.syncSelection.copyWith(
        savedBeneficiary: savedBeneficiary,
        recentTransactions: recentTransactions,
        appPreferences: appPreferences,
      ),
    );
  }

  Future<bool> syncData() async {
    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      await _service.syncData(state.syncSelection);

      state = state.copyWith(
        isSyncing: false,
        successMessage: 'Data synced successfully',
      );
      return true;
    } on SocketException {
      state = state.copyWith(
        isSyncing: false,
        error: 'No internet connection. Please check your network.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: 'Failed to sync data.',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }

  void reset() {
    state = const DeviceLinkingState();
  }
}

// ==================== DEVICE LINKING PROVIDERS ====================

final deviceLinkingServiceProvider = Provider<DeviceLinkingService>((ref) {
  return DeviceLinkingService(
    baseUrl: 'https://api.kudipay.com/api/v1',
  );
});

final deviceLinkingProvider =
    StateNotifierProvider<DeviceLinkingNotifier, DeviceLinkingState>((ref) {
  final service = ref.watch(deviceLinkingServiceProvider);
  return DeviceLinkingNotifier(service);
});
