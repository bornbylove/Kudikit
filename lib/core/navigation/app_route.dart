// lib/core/navigation/app_router.dart
//
// Single source of truth for all navigation in the app.
//
// USAGE — pushing a screen:
//
//   // No arguments:
//   Navigator.pushNamed(context, AppRoutes.home);
//
//   // With arguments:
//   Navigator.pushNamed(context, AppRoutes.upgradeTier,
//     arguments: UpgradeTierArgs(tier: currentTierObj));
//
//   // Replace current screen:
//   Navigator.pushReplacementNamed(context, AppRoutes.login);
//
//   // Clear stack (e.g. after login):
//   Navigator.pushNamedAndRemoveUntil(
//     context, AppRoutes.home, (route) => false);
//
// HOW TO ADD A NEW ROUTE:
//   1. Add a constant to AppRoutes
//   2. Add an args class below if the screen needs parameters
//   3. Add a case to AppRouter.generateRoute

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model imports (needed for typed args classes)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/model/request/request_model.dart';
import 'package:kudipay/presentation/notification/notification_category_screen.dart'
    show NotificationCategory;

// ─────────────────────────────────────────────────────────────────────────────
// Screen imports
// ─────────────────────────────────────────────────────────────────────────────

import 'package:kudipay/presentation/splashscreen/splashscreen.dart';
import 'package:kudipay/presentation/onboarding/onboarding_screen.dart';
import 'package:kudipay/features/auth/presentation/pages/login_page.dart';
import 'package:kudipay/presentation/signup/signup.dart';
import 'package:kudipay/presentation/signup/signup_verify.dart';        // EmailVerifySignup
import 'package:kudipay/presentation/passcode/create_passcode.dart';    // PasscodeCreationScreen
import 'package:kudipay/presentation/passcode/confirm_passcode.dart';   // PasscodeConfirmationScreen
import 'package:kudipay/presentation/account_ready/account_ready.dart';
import 'package:kudipay/shared/widgets/bottom_nav.dart';
import 'package:kudipay/presentation/homescreen/home_screen.dart';

// KYC
import 'package:kudipay/presentation/Identity/chooseID.dart';            // IdVerificationScreen
import 'package:kudipay/presentation/Identity/confirm_info.dart';
import 'package:kudipay/presentation/selfie/selfie_instruction.dart';    // SelfieInstructionsScreen
import 'package:kudipay/presentation/selfie/selfie_capture_screen.dart';
import 'package:kudipay/presentation/address/verify_address.dart';       // AddressVerificationScreen
import 'package:kudipay/presentation/Identity/upload_ID.dart';           // UploadIdCardScreen

// Transfer
import 'package:kudipay/presentation/transfer/single_transfer/transfer_amount_screen.dart';
import 'package:kudipay/presentation/transfer/single_transfer/add_recipient_screen.dart';   // AddRecipientsManuallyScreen
import 'package:kudipay/presentation/transfer/bulk_transfer/bulk_transfer_upload_file_screen.dart';
import 'package:kudipay/presentation/transfer/bulk_transfer/bulk_transfer_preview.dart';

// Bills
import 'package:kudipay/features/bills/presentation/pages/airtime/airtime_phone_screen.dart';
import 'package:kudipay/features/bills/presentation/pages/airtime/airtime_amount_screen.dart';
import 'package:kudipay/features/bills/presentation/pages/data/data_phone_screen.dart';
import 'package:kudipay/features/bills/presentation/pages/data/data_plan_screen.dart';
import 'package:kudipay/features/bills/presentation/pages/cable_tv/cable_tv_screen.dart';
import 'package:kudipay/features/bills/presentation/pages/electricity/electricity_screen.dart';
import 'package:kudipay/features/bills/presentation/pages/bill_transaction_detail.dart';

// Wallet / Add money
import 'package:kudipay/features/wallet/presentation/pages/addmoney/add_money_screen.dart';
import 'package:kudipay/presentation/bankdeposit/select_bank.dart';
import 'package:kudipay/presentation/bankdeposit/bank_ussd_screen.dart';
import 'package:kudipay/presentation/bankdeposit/ussd_code_display_screen.dart';
import 'package:kudipay/presentation/qrcode/qr_code_screen.dart';

// Transactions
import 'package:kudipay/presentation/transaction/transaction_screen.dart';
import 'package:kudipay/presentation/transaction/transaction_filter_screen.dart';

// Requests
import 'package:kudipay/presentation/request/request_money_main_screen.dart';
import 'package:kudipay/presentation/request/request_money_screen.dart';
import 'package:kudipay/presentation/request/select_recipient_screen.dart';
import 'package:kudipay/presentation/request/preview_request_screen.dart';
import 'package:kudipay/presentation/request/my_request_screen.dart';
import 'package:kudipay/presentation/request/request_detail_screen.dart';
import 'package:kudipay/presentation/request/request_sent_screen.dart';

// Cashout
import 'package:kudipay/presentation/cashout/cashout_map_screen.dart';
import 'package:kudipay/presentation/cashout/enter_amount_screen.dart';
import 'package:kudipay/presentation/cashout/agent_detail_screen.dart';  // AgentDetailsScreen

// Agent
import 'package:kudipay/presentation/agent/become_agent_screen.dart';       // BecomeAgentLandingScreen
import 'package:kudipay/presentation/agent/agent_registration_screen.dart'; // AgentRegistrationFlow
import 'package:kudipay/presentation/agent/agent_dashboard_screen.dart';

// Tier
import 'package:kudipay/presentation/tier/tier_selection_screen.dart';
import 'package:kudipay/presentation/tier/upgrade_tier_screen.dart';
import 'package:kudipay/presentation/tier/upgrade_success_screen.dart';

// Notifications
import 'package:kudipay/presentation/notification/notification_category_screen.dart';
import 'package:kudipay/presentation/notification/notification_preference_screen.dart';

// Profile / Settings
import 'package:kudipay/presentation/profile/profile_screen.dart';          // UserProfileScreen
import 'package:kudipay/presentation/transactionpin/transaction_pin_screen.dart';
import 'package:kudipay/presentation/linkdevice/link_device_screen.dart';
import 'package:kudipay/presentation/linkdevice/data_sync.dart';             // DataSyncScreen

// Support / Tickets
import 'package:kudipay/presentation/support/support_screen.dart';
import 'package:kudipay/presentation/ticket/features/tickets/presentation/screens/tickets_screen.dart';

// Tribe
import 'package:kudipay/presentation/tribe/choose_tribe.dart';              // TribeScreen

// ─────────────────────────────────────────────────────────────────────────────
// AppRoutes — all route name constants
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppRoutes {
  // Auth / Onboarding
  static const splash            = '/';
  static const onboarding        = '/onboarding';
  static const login             = '/login';
  static const signup            = '/signup';
  static const signupVerify      = '/signup/verify';
  static const createPasscode    = '/passcode/create';
  static const confirmPasscode   = '/passcode/confirm';
  static const accountReady      = '/account-ready';

  // Home
  static const bottomNav = '/nav';
  static const home      = '/home';

  // KYC
  static const chooseId               = '/kyc/choose-id';
  static const confirmInfo            = '/kyc/confirm-info';
  static const selfieInstructions     = '/kyc/selfie-instructions';
  static const selfieCapture          = '/kyc/selfie-capture';
  static const verifyAddress          = '/kyc/address';
  static const uploadId               = '/kyc/upload-id';

  // Transfer
  static const transferAmount      = '/transfer/amount';
  static const addRecipient        = '/transfer/add-recipient';
  static const bulkTransferUpload  = '/transfer/bulk/upload';
  static const bulkTransferPreview = '/transfer/bulk/preview';

  // Bills
  static const airtimePhone          = '/bills/airtime/phone';
  static const airtimeAmount         = '/bills/airtime/amount';
  static const dataPhone             = '/bills/data/phone';
  static const dataPlans             = '/bills/data/plans';
  static const cableTv               = '/bills/cable-tv';
  static const electricity           = '/bills/electricity';
  static const billTransactionDetail = '/bills/transaction-detail';

  // Wallet / Add money
  static const addMoney        = '/wallet/add-money';
  static const selectBank      = '/wallet/select-bank';
  static const bankUssd        = '/wallet/bank-ussd';
  static const ussdCodeDisplay = '/wallet/ussd-display';
  static const qrCode          = '/wallet/qr-code';

  // Transactions
  static const transactions      = '/transactions';
  static const transactionFilter = '/transactions/filter';

  // Requests
  static const requestMoneyMain = '/request/main';
  static const requestMoney     = '/request/new';
  static const selectRecipients = '/request/select-recipients';
  static const previewRequest   = '/request/preview';
  static const myRequests       = '/request/my-requests';
  static const requestDetail    = '/request/detail';
  static const requestSent      = '/request/sent';

  // Cashout
  static const cashoutMap  = '/cashout/map';
  static const enterAmount = '/cashout/amount';

  // Agent
  static const becomeAgent       = '/agent/become';
  static const agentRegistration = '/agent/register';
  static const agentDetails      = '/agent/details';
  static const agentDashboard    = '/agent/dashboard';

  // Tier
  static const tierSelection  = '/tier/select';
  static const upgradeTier    = '/tier/upgrade';
  static const upgradeSuccess = '/tier/success';

  // Notifications
  static const notificationCategory   = '/notifications/category';
  static const notificationPreference = '/notifications/preference';

  // Profile / Settings
  static const profile        = '/profile';
  static const transactionPin = '/settings/transaction-pin';
  static const linkDevice     = '/settings/link-device';
  static const dataSync       = '/settings/data-sync';

  // Support / Tickets
  static const support = '/support';
  static const tickets = '/support/tickets';

  // Tribe
  static const tribe = '/tribe';
}

// ─────────────────────────────────────────────────────────────────────────────
// Route argument classes
// One class per screen that requires typed arguments.
// ─────────────────────────────────────────────────────────────────────────────

/// Args for [AppRoutes.signupVerify].
/// All four fields are returned by the signup step before navigating here.
class SignupVerifyArgs {
  final String email;
  final String phoneNumber;
  final String passcode;
  final String otpId;
  const SignupVerifyArgs({
    required this.email,
    required this.phoneNumber,
    required this.passcode,
    required this.otpId,
  });
}

/// Args for [AppRoutes.confirmInfo].
/// Typed as [UserInfo] — not a raw Map<String, dynamic>.
class ConfirmInfoArgs {
  final UserInfo userInfo;
  const ConfirmInfoArgs({required this.userInfo});
}

/// Args for [AppRoutes.billTransactionDetail].
/// Mirrors the [BillTransactionDetail] constructor exactly.
class BillTransactionDetailArgs {
  final String title;
  final String transactionId;
  final String billType;
  final String providerName;
  final double amount;
  final DateTime transactionDate;
  final String recipientNumber;
  final String recipientName;
  final String status;
  final Map<String, String> extraDetails;
  const BillTransactionDetailArgs({
    required this.title,
    required this.transactionId,
    required this.billType,
    required this.providerName,
    required this.amount,
    required this.transactionDate,
    required this.recipientNumber,
    required this.recipientName,
    this.status = 'Successful',
    this.extraDetails = const {},
  });
}

/// Args for [AppRoutes.requestDetail].
class RequestDetailArgs {
  final MoneyRequest request;
  const RequestDetailArgs({required this.request});
}

/// Args for [AppRoutes.requestSent].
class RequestSentArgs {
  final MoneyRequest request;
  const RequestSentArgs({required this.request});
}

/// Args for [AppRoutes.enterAmount].
class EnterAmountArgs {
  final dynamic agent; // replace with your Agent entity type
  const EnterAmountArgs({required this.agent});
}

/// Args for [AppRoutes.agentDetails].
class AgentDetailsArgs {
  final dynamic agent;
  const AgentDetailsArgs({required this.agent});
}

/// Args for [AppRoutes.upgradeTier].
class UpgradeTierArgs {
  final dynamic tier; // replace with your Tier entity type
  const UpgradeTierArgs({required this.tier});
}

/// Args for [AppRoutes.upgradeSuccess].
class UpgradeSuccessArgs {
  final dynamic tier;
  const UpgradeSuccessArgs({required this.tier});
}

/// Args for [AppRoutes.notificationCategory].
class NotificationCategoryArgs {
  final NotificationCategory category;
  const NotificationCategoryArgs({required this.category});
}

class UploadDocumentArgs {
  final dynamic tier;
  const UploadDocumentArgs({required this.tier});
}

// ─────────────────────────────────────────────────────────────────────────────
// AppRouter
// ─────────────────────────────────────────────────────────────────────────────

class AppRouter {
  /// Wire this to MaterialApp.onGenerateRoute:
  ///   onGenerateRoute: AppRouter.generateRoute
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {

      // ── Auth / Onboarding ─────────────────────────────────────────────────
      case AppRoutes.splash:
        return _build(const SplashScreen());
      case AppRoutes.onboarding:
        return _build(const OnboardingScreen());
      case AppRoutes.login:
        return _build(const LoginPage());
      case AppRoutes.signup:
        return _build(const SignUpScreen());
      case AppRoutes.signupVerify:
        // EmailVerifySignup requires email, phoneNumber, passcode, otpId.
        final a = args as SignupVerifyArgs;
        return _build(EmailVerifySignup(
          email: a.email,
          phoneNumber: a.phoneNumber,
          passcode: a.passcode,
          otpId: a.otpId,
        ));
      case AppRoutes.createPasscode:
        return _build(const PasscodeCreationScreen());
      case AppRoutes.confirmPasscode:
        return _build(const PasscodeConfirmationScreen());
      case AppRoutes.accountReady:
        return _build(const AccountReadyScreen());

      // ── Home ─────────────────────────────────────────────────────────────
      case AppRoutes.bottomNav:
        return _build(const BottomNavBar());
      case AppRoutes.home:
        return _build(const HomeScreen());

      // ── KYC ──────────────────────────────────────────────────────────────
      case AppRoutes.chooseId:
        return _build(const IdVerificationScreen());
      case AppRoutes.confirmInfo:
        final a = args as ConfirmInfoArgs;
        return _build(ConfirmInfoScreen(userInfo: a.userInfo));
      case AppRoutes.selfieInstructions:
        return _build(const SelfieInstructionsScreen());
      case AppRoutes.selfieCapture:
        return _build(const SelfieCaptureScreen());
      case AppRoutes.verifyAddress:
        return _build(const AddressVerificationScreen());
      case AppRoutes.uploadId:
        return _build(const UploadIdCardScreen());

      // ── Transfer ──────────────────────────────────────────────────────────
      case AppRoutes.transferAmount:
        return _build(const TransferAmountScreen());
      case AppRoutes.addRecipient:
        return _build(const AddRecipientsManuallyScreen());
      case AppRoutes.bulkTransferUpload:
        return _build(const BulkTransferUploadFileScreen());
      case AppRoutes.bulkTransferPreview:
        return _build(const BulkTransferPreviewScreen());

      // ── Bills ─────────────────────────────────────────────────────────────
      case AppRoutes.airtimePhone:
        return _build(const AirtimePhoneScreen());
      case AppRoutes.airtimeAmount:
        return _build(const AirtimeAmountScreen());
      case AppRoutes.dataPhone:
        return _build(const DataPhoneScreen());
      case AppRoutes.dataPlans:
        return _build(const DataPlansScreen());
      case AppRoutes.cableTv:
        return _build(const CableTvBillerScreen());
      case AppRoutes.electricity:
        return _build(const ElectricityScreen());
      case AppRoutes.billTransactionDetail:
        // BillTransactionDetail requires all fields — pass via BillTransactionDetailArgs.
        final a = args as BillTransactionDetailArgs;
        return _build(BillTransactionDetail(
          title: a.title,
          transactionId: a.transactionId,
          billType: a.billType,
          providerName: a.providerName,
          amount: a.amount,
          transactionDate: a.transactionDate,
          recipientNumber: a.recipientNumber,
          recipientName: a.recipientName,
          status: a.status,
          extraDetails: a.extraDetails,
        ));

      // ── Wallet / Add money ────────────────────────────────────────────────
      case AppRoutes.addMoney:
        return _build(const AddMoneyScreen());
      case AppRoutes.selectBank:
        return _build(const SelectBankScreen());
      case AppRoutes.bankUssd:
        return _build(const BankUssdScreen());
      case AppRoutes.ussdCodeDisplay:
        return _build(const UssdCodeDisplayScreen());
      case AppRoutes.qrCode:
        return _build(const QrCodeScreen());

      // ── Transactions ──────────────────────────────────────────────────────
      case AppRoutes.transactions:
        return _build(const TransactionsScreen());
      case AppRoutes.transactionFilter:
        return _build(const TransactionFilterScreen());

      // ── Requests ──────────────────────────────────────────────────────────
      case AppRoutes.requestMoneyMain:
        return _build(const RequestMoneyMainScreen());
      case AppRoutes.requestMoney:
        return _build(const RequestMoneyScreen());
      case AppRoutes.selectRecipients:
        return _build(const SelectRecipientsScreen());
      case AppRoutes.previewRequest:
        return _build(const PreviewRequestScreen());
      case AppRoutes.myRequests:
        return _build(const MyRequestsScreen());
      case AppRoutes.requestDetail:
        final a = args as RequestDetailArgs;
        return _build(RequestDetailScreen(request: a.request));
      case AppRoutes.requestSent:
        // RequestSentScreen requires a MoneyRequest — pass via RequestSentArgs.
        final a = args as RequestSentArgs;
        return _build(RequestSentScreen(request: a.request));

      // ── Cashout ───────────────────────────────────────────────────────────
      case AppRoutes.cashoutMap:
        return _build(const CashOutMapScreen());
      case AppRoutes.enterAmount:
        final a = args as EnterAmountArgs;
        return _build(EnterAmountScreen(agent: a.agent));

      // ── Agent ─────────────────────────────────────────────────────────────
      case AppRoutes.becomeAgent:
        return _build(const BecomeAgentLandingScreen());
      case AppRoutes.agentRegistration:
        return _build(const AgentRegistrationFlow());
      case AppRoutes.agentDetails:
        final a = args as AgentDetailsArgs;
        return _build(AgentDetailsScreen(agent: a.agent));
      case AppRoutes.agentDashboard:
        return _build(const AgentDashboardScreen());

      // ── Tier ──────────────────────────────────────────────────────────────
      case AppRoutes.tierSelection:
        return _build(const TierSelectionScreen());
      case AppRoutes.upgradeTier:
        final a = args as UpgradeTierArgs;
        return _build(UpgradeTierScreen(tier: a.tier));
      case AppRoutes.upgradeSuccess:
        final a = args as UpgradeSuccessArgs;
        return _build(UpgradeSuccessScreen(tier: a.tier));

      // ── Notifications ─────────────────────────────────────────────────────
      case AppRoutes.notificationCategory:
        // NotificationCategoryScreen requires a NotificationCategory enum value.
        final a = args as NotificationCategoryArgs;
        return _build(NotificationCategoryScreen(category: a.category));
      case AppRoutes.notificationPreference:
        return _build(const NotificationPreferenceScreen());

      // ── Profile / Settings ────────────────────────────────────────────────
      case AppRoutes.profile:
        return _build(const UserProfileScreen());
      case AppRoutes.transactionPin:
        return _build(const CreateTransactionPinScreen());
      case AppRoutes.linkDevice:
        return _build(const LinkDeviceScreen());
      case AppRoutes.dataSync:
        return _build(const DataSyncScreen());

      // ── Support / Tickets ─────────────────────────────────────────────────
      case AppRoutes.support:
        return _build(const SupportScreen());
      case AppRoutes.tickets:
        return _build(const TicketsScreen());

      // ── Tribe ─────────────────────────────────────────────────────────────
      case AppRoutes.tribe:
        return _build(const TribeScreen());

      // ── Fallback ──────────────────────────────────────────────────────────
      default:
        return _build(const SplashScreen());
    }
  }

  static MaterialPageRoute<dynamic> _build(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}