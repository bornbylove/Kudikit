import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/model/device/device_metadata.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/services/auth_services.dart';
import 'package:kudipay/services/device_info_services.dart';
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
  final String? otpReference;
  final bool isCodeSent;
  final bool isVerified;
  final DateTime? codeSentAt;

  const DeviceLinkingData({
    this.email,
    this.maskedEmail,
    this.oldDeviceName,
    this.verificationCode,
    this.otpReference,
    this.isCodeSent = false,
    this.isVerified = false,
    this.codeSentAt,
  });

  DeviceLinkingData copyWith({
    String? email,
    String? maskedEmail,
    String? oldDeviceName,
    String? verificationCode,
    String? otpReference,
    bool? isCodeSent,
    bool? isVerified,
    DateTime? codeSentAt,
  }) {
    return DeviceLinkingData(
      email: email ?? this.email,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      oldDeviceName: oldDeviceName ?? this.oldDeviceName,
      verificationCode: verificationCode ?? this.verificationCode,
      otpReference: otpReference ?? this.otpReference,
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
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
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
  final AuthService _authService;

  DeviceLinkingService({required AuthService authService})
      : _authService = authService;

  Future<DeviceLinkingData> getUserDeviceInfo() async {
    return _mockGetUserDeviceInfo();
  }

  // Resend the DEVICE_LINK OTP. The original OTP for a 202 login challenge is
  // dispatched by POST /auth/login itself — this call is only used when the
  // user asks to resend the code.
  Future<bool> sendVerificationCode(
    String email,
    VerificationMethod method,
    DeviceMetadata deviceMetadata, // NEW
  ) async {
    await _authService.sendOtp(
      identifier: email,
      purpose: OtpPurpose.deviceLink,
    );
    return true;
  }

  // Verify the DEVICE_LINK code then complete the login for the challenged
  // device: verifyOtp consumes the code, verifyDeviceLogin marks the current
  // deviceFingerprint trusted and returns the AuthTokenResponse envelope.
  Future<Map<String, dynamic>> verifyCode({
    required String code,
    required String otpReference,
  }) async {
    await _authService.verifyOtp(
      otpReference: otpReference,
      code: code,
      purpose: OtpPurpose.deviceLink,
    );
    return _authService.verifyDeviceLogin(otpReference: otpReference);
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

  Future<bool> _mockSyncData(DataSyncSelection selection) async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }
}

// ==================== NOTIFIER ====================

class DeviceLinkingNotifier extends StateNotifier<DeviceLinkingState> {
  final DeviceLinkingService _service;
  final Future<void> Function(Map<String, dynamic> data)? _onDeviceVerified;

  DeviceLinkingNotifier(this._service, {Future<void> Function(Map<String, dynamic> data)? onDeviceVerified})
      : _onDeviceVerified = onDeviceVerified,
        super(const DeviceLinkingState());

  // Seeds the notifier with the 202 login challenge so the existing
  // SignInVerifyEmailScreen can drive device verification end-to-end. The
  // DEVICE_LINK OTP has ALREADY been dispatched by POST /auth/login.
  void startDeviceVerification({
    required String otpReference,
    required String identifier,
    String maskedIdentifier = '',
  }) {
    state = const DeviceLinkingState().copyWith(
      data: DeviceLinkingData(
        email: identifier,
        maskedEmail: maskedIdentifier,
        otpReference: otpReference,
      ),
    );
  }

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
        deviceMetadata,   // NEW — forwarded to the service / API call
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
      final otpReference = state.data?.otpReference;
      if (otpReference == null || otpReference.isEmpty) {
        state = state.copyWith(
          isVerifyingCode: false,
          error: 'No active device verification found. Please log in again.',
        );
        return false;
      }

      final envelope = await _service.verifyCode(
        code: code,
        otpReference: otpReference,
      );
      final data = envelope['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Malformed device verification response.');
      }

      // Complete the session (shared with login()/registration) so the
      // authenticated state is set from exactly one place.
      await _onDeviceVerified?.call(data);

      state = state.copyWith(
        isVerifyingCode: false,
        data: state.data?.copyWith(
          verificationCode: code,
          isVerified: true,
        ),
      );
      return true;
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
    authService: ref.watch(authServiceProvider),
  );
});

final deviceLinkingProvider =
    StateNotifierProvider<DeviceLinkingNotifier, DeviceLinkingState>((ref) {
  final service = ref.watch(deviceLinkingServiceProvider);
  return DeviceLinkingNotifier(
    service,
    onDeviceVerified: (data) =>
        ref.read(authProvider.notifier).completeSession(data),
  );
});