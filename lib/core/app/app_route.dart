// lib/core/app/app_route.dart
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

import 'package:kudipay/core/app/app_routes.dart';
import 'package:kudipay/features/notification/presentation/pages/notification_category_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen imports
// ─────────────────────────────────────────────────────────────────────────────

import 'package:kudipay/features/splashscreen/presentation/pages/splashscreen.dart';
import 'package:kudipay/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:kudipay/features/auth/presentation/pages/login_page.dart';
import 'package:kudipay/features/signup/presentation/pages/signup.dart';
import 'package:kudipay/features/signup/presentation/pages/signup_verify.dart'; // EmailVerifySignup
import 'package:kudipay/features/account_ready/presentation/pages/account_ready.dart';
import 'package:kudipay/shared/widgets/bottom_nav.dart';
import 'package:kudipay/features/homescreen/presentation/pages/home_screen.dart';

// KYC
import 'package:kudipay/features/identity/presentation/pages/choose_id.dart'; // IdVerificationScreen
import 'package:kudipay/features/identity/presentation/pages/confirm_info.dart';
import 'package:kudipay/features/selfie/presentation/pages/selfie_instruction.dart'; // SelfieInstructionsScreen
import 'package:kudipay/features/selfie/presentation/pages/selfie_capture_screen.dart';
import 'package:kudipay/features/address/presentation/pages/verify_address.dart'; // AddressVerificationScreen
import 'package:kudipay/features/identity/presentation/pages/upload_id.dart'; // UploadIdCardScreen

// Transfer
import 'package:kudipay/features/transfer/presentation/pages/single_transfer/transfer_amount_screen.dart';
import 'package:kudipay/features/transfer/presentation/pages/single_transfer/transfer_receipt_screen.dart';
import 'package:kudipay/features/transfer/presentation/pages/single_transfer/add_recipient_screen.dart'; // AddRecipientsManuallyScreen
import 'package:kudipay/features/transfer/presentation/pages/bulk_transfer/bulk_transfer_upload_file_screen.dart';
import 'package:kudipay/features/transfer/presentation/pages/bulk_transfer/bulk_transfer_preview.dart';

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
import 'package:kudipay/features/bankdeposit/presentation/pages/select_bank.dart';
import 'package:kudipay/features/bankdeposit/presentation/pages/bank_ussd_screen.dart';
import 'package:kudipay/features/bankdeposit/presentation/pages/ussd_code_display_screen.dart';
import 'package:kudipay/features/qrcode/presentation/pages/qr_code_screen.dart';

// Transactions
import 'package:kudipay/features/transaction/presentation/pages/transaction_screen.dart';
import 'package:kudipay/features/transaction/presentation/pages/transaction_filter_screen.dart';

// Requests
import 'package:kudipay/features/request/presentation/pages/request_money_main_screen.dart';
import 'package:kudipay/features/request/presentation/pages/request_money_screen.dart';
import 'package:kudipay/features/request/presentation/pages/select_recipient_screen.dart';
import 'package:kudipay/features/request/presentation/pages/preview_request_screen.dart';
import 'package:kudipay/features/request/presentation/pages/my_request_screen.dart';
import 'package:kudipay/features/request/presentation/pages/request_detail_screen.dart';
import 'package:kudipay/features/request/presentation/pages/request_sent_screen.dart';

// Cashout
import 'package:kudipay/features/cashout/presentation/pages/cashout_map_screen.dart';
import 'package:kudipay/features/cashout/presentation/pages/enter_amount_screen.dart';
import 'package:kudipay/features/cashout/presentation/pages/agent_detail_screen.dart'; // AgentDetailsScreen

// Agent
import 'package:kudipay/features/agent/presentation/pages/become_agent_screen.dart'; // BecomeAgentLandingScreen
import 'package:kudipay/features/agent/presentation/pages/agent_registration_flow.dart'; // AgentRegistrationFlow
import 'package:kudipay/features/agent/presentation/pages/agent_dashboard_screen.dart';

// Tier
import 'package:kudipay/features/tier/presentation/pages/tier_selection_screen.dart';
import 'package:kudipay/features/tier/presentation/pages/upgrade_tier_screen.dart';
import 'package:kudipay/features/tier/presentation/pages/upgrade_success_screen.dart';

// Notifications
import 'package:kudipay/features/notification/presentation/pages/notification_preference_screen.dart';

// Profile / Settings
import 'package:kudipay/features/profile/presentation/pages/profile_screen.dart'; // UserProfileScreen
import 'package:kudipay/features/transactionpin/presentation/pages/transaction_pin_screen.dart';
import 'package:kudipay/features/linkdevice/presentation/pages/link_device_screen.dart';
import 'package:kudipay/features/linkdevice/presentation/pages/data_sync.dart'; // DataSyncScreen

// Support / Tickets
import 'package:kudipay/features/support/presentation/pages/support_screen.dart';
import 'package:kudipay/features/ticket/features/tickets/presentation/screens/tickets_screen.dart';

// Tribe
import 'package:kudipay/features/tribe/presentation/pages/choose_tribe.dart'; // TribeScreen

export 'package:kudipay/core/app/app_routes.dart';

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
        final loginArgs = args as LoginArgs?;
        return _build(LoginPage(
          email: loginArgs?.email,
          phoneNumber: loginArgs?.phoneNumber,
        ));
      case AppRoutes.signup:
        return _build(const SignUpScreen());
      case AppRoutes.signupVerify:
        // EmailVerifySignup requires email, phoneNumber, passcode,
        // confirmPasscode, otpId.
        final a = args as SignupVerifyArgs;
        return _build(EmailVerifySignup(
          email: a.email,
          phoneNumber: a.phoneNumber,
          passcode: a.passcode,
          confirmPasscode: a.confirmPasscode,
          otpId: a.otpId,
        ));
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
      case AppRoutes.transferRecipient:
        return _build(const TransferRecipientScreen());
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
