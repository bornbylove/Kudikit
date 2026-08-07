import 'package:kudipay/features/request/domain/entities/request_model.dart';
import 'package:kudipay/model/user/user_info.dart';

/// Notification preference categories used in routing args.
enum NotificationCategory {
  transaction,
  bills,
  rewards,
  appUpdates,
}

/// All route name constants — safe to import without pulling in screen widgets.
abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const signupVerify = '/signup/verify';
  static const createPasscode = '/passcode/create';
  static const confirmPasscode = '/passcode/confirm';
  static const accountReady = '/account-ready';

  static const bottomNav = '/nav';
  static const home = '/home';

  static const chooseId = '/kyc/choose-id';
  static const confirmInfo = '/kyc/confirm-info';
  static const selfieInstructions = '/kyc/selfie-instructions';
  static const selfieCapture = '/kyc/selfie-capture';
  static const verifyAddress = '/kyc/address';
  static const uploadId = '/kyc/upload-id';

  static const transferAmount = '/transfer/amount';
  static const transferRecipient = '/transfer/recipient';
  static const addRecipient = '/transfer/add-recipient';
  static const bulkTransferUpload = '/transfer/bulk/upload';
  static const bulkTransferPreview = '/transfer/bulk/preview';

  static const airtimePhone = '/bills/airtime/phone';
  static const airtimeAmount = '/bills/airtime/amount';
  static const dataPhone = '/bills/data/phone';
  static const dataPlans = '/bills/data/plans';
  static const cableTv = '/bills/cable-tv';
  static const electricity = '/bills/electricity';
  static const billTransactionDetail = '/bills/transaction-detail';

  static const addMoney = '/wallet/add-money';
  static const selectBank = '/wallet/select-bank';
  static const bankUssd = '/wallet/bank-ussd';
  static const ussdCodeDisplay = '/wallet/ussd-display';
  static const qrCode = '/wallet/qr-code';

  static const transactions = '/transactions';
  static const transactionFilter = '/transactions/filter';

  static const requestMoneyMain = '/request/main';
  static const requestMoney = '/request/new';
  static const selectRecipients = '/request/select-recipients';
  static const previewRequest = '/request/preview';
  static const myRequests = '/request/my-requests';
  static const requestDetail = '/request/detail';
  static const requestSent = '/request/sent';

  static const cashoutMap = '/cashout/map';
  static const enterAmount = '/cashout/amount';

  static const becomeAgent = '/agent/become';
  static const agentRegistration = '/agent/register';
  static const agentDetails = '/agent/details';
  static const agentDashboard = '/agent/dashboard';

  static const tierSelection = '/tier/select';
  static const upgradeTier = '/tier/upgrade';
  static const upgradeSuccess = '/tier/success';

  static const notificationCategory = '/notifications/category';
  static const notificationPreference = '/notifications/preference';

  static const profile = '/profile';
  static const transactionPin = '/settings/transaction-pin';
  static const linkDevice = '/settings/link-device';
  static const dataSync = '/settings/data-sync';

  static const support = '/support';
  static const tickets = '/support/tickets';

  static const tribe = '/tribe';
}

class LoginArgs {
  final String? email;
  final String? phoneNumber;

  const LoginArgs({this.email, this.phoneNumber});
}

class SignupVerifyArgs {
  final String email;
  final String phoneNumber;
  final String passcode;
  final String confirmPasscode;
  final String otpId;

  const SignupVerifyArgs({
    required this.email,
    required this.phoneNumber,
    required this.passcode,
    required this.confirmPasscode,
    required this.otpId,
  });
}

class ConfirmInfoArgs {
  final UserInfo userInfo;
  const ConfirmInfoArgs({required this.userInfo});
}

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

class RequestDetailArgs {
  final MoneyRequest request;
  const RequestDetailArgs({required this.request});
}

class RequestSentArgs {
  final MoneyRequest request;
  const RequestSentArgs({required this.request});
}

class EnterAmountArgs {
  final dynamic agent;
  const EnterAmountArgs({required this.agent});
}

class AgentDetailsArgs {
  final dynamic agent;
  const AgentDetailsArgs({required this.agent});
}

class UpgradeTierArgs {
  final dynamic tier;
  const UpgradeTierArgs({required this.tier});
}

class UpgradeSuccessArgs {
  final dynamic tier;
  const UpgradeSuccessArgs({required this.tier});
}

class NotificationCategoryArgs {
  final NotificationCategory category;
  const NotificationCategoryArgs({required this.category});
}

class UploadDocumentArgs {
  final dynamic tier;
  const UploadDocumentArgs({required this.tier});
}
