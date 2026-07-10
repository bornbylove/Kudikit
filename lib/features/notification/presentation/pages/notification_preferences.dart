class NotificationPreferences {
  // Transaction notifications
  final bool transactionSuccess;
  final bool depositNotification;
  final bool withdrawalNotification;
  final bool largeTransactionAlert;

  // Bills & Reminders
  final bool billPaymentReminder;
  final bool failedBillPaymentAlert;

  // Rewards & Offers
  final bool rewardEarnedAlert;
  final bool rewardExpiryAlert;
  final bool promotionalOffers;
  final bool partnerOffers;

  // App Updates & Tips
  final bool newFeatureAnnouncements;
  final bool tutorialPrompt;
  final bool feedbackRequest;
  final bool announcementBanners;

  NotificationPreferences({
    // Transaction defaults - all true
    this.transactionSuccess = true,
    this.depositNotification = true,
    this.withdrawalNotification = true,
    this.largeTransactionAlert = true,

    // Bills & Reminders defaults - all true
    this.billPaymentReminder = true,
    this.failedBillPaymentAlert = true,

    // Rewards & Offers defaults - all true
    this.rewardEarnedAlert = true,
    this.rewardExpiryAlert = true,
    this.promotionalOffers = true,
    this.partnerOffers = true,

    // App Updates & Tips defaults - all true
    this.newFeatureAnnouncements = true,
    this.tutorialPrompt = true,
    this.feedbackRequest = true,
    this.announcementBanners = true,
  });

  NotificationPreferences copyWith({
    bool? transactionSuccess,
    bool? depositNotification,
    bool? withdrawalNotification,
    bool? largeTransactionAlert,
    bool? billPaymentReminder,
    bool? failedBillPaymentAlert,
    bool? rewardEarnedAlert,
    bool? rewardExpiryAlert,
    bool? promotionalOffers,
    bool? partnerOffers,
    bool? newFeatureAnnouncements,
    bool? tutorialPrompt,
    bool? feedbackRequest,
    bool? announcementBanners,
  }) {
    return NotificationPreferences(
      transactionSuccess: transactionSuccess ?? this.transactionSuccess,
      depositNotification: depositNotification ?? this.depositNotification,
      withdrawalNotification:
          withdrawalNotification ?? this.withdrawalNotification,
      largeTransactionAlert:
          largeTransactionAlert ?? this.largeTransactionAlert,
      billPaymentReminder: billPaymentReminder ?? this.billPaymentReminder,
      failedBillPaymentAlert:
          failedBillPaymentAlert ?? this.failedBillPaymentAlert,
      rewardEarnedAlert: rewardEarnedAlert ?? this.rewardEarnedAlert,
      rewardExpiryAlert: rewardExpiryAlert ?? this.rewardExpiryAlert,
      promotionalOffers: promotionalOffers ?? this.promotionalOffers,
      partnerOffers: partnerOffers ?? this.partnerOffers,
      newFeatureAnnouncements:
          newFeatureAnnouncements ?? this.newFeatureAnnouncements,
      tutorialPrompt: tutorialPrompt ?? this.tutorialPrompt,
      feedbackRequest: feedbackRequest ?? this.feedbackRequest,
      announcementBanners: announcementBanners ?? this.announcementBanners,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionSuccess': transactionSuccess,
      'depositNotification': depositNotification,
      'withdrawalNotification': withdrawalNotification,
      'largeTransactionAlert': largeTransactionAlert,
      'billPaymentReminder': billPaymentReminder,
      'failedBillPaymentAlert': failedBillPaymentAlert,
      'rewardEarnedAlert': rewardEarnedAlert,
      'rewardExpiryAlert': rewardExpiryAlert,
      'promotionalOffers': promotionalOffers,
      'partnerOffers': partnerOffers,
      'newFeatureAnnouncements': newFeatureAnnouncements,
      'tutorialPrompt': tutorialPrompt,
      'feedbackRequest': feedbackRequest,
      'announcementBanners': announcementBanners,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      transactionSuccess: json['transactionSuccess'] ?? true,
      depositNotification: json['depositNotification'] ?? true,
      withdrawalNotification: json['withdrawalNotification'] ?? true,
      largeTransactionAlert: json['largeTransactionAlert'] ?? true,
      billPaymentReminder: json['billPaymentReminder'] ?? true,
      failedBillPaymentAlert: json['failedBillPaymentAlert'] ?? true,
      rewardEarnedAlert: json['rewardEarnedAlert'] ?? true,
      rewardExpiryAlert: json['rewardExpiryAlert'] ?? true,
      promotionalOffers: json['promotionalOffers'] ?? true,
      partnerOffers: json['partnerOffers'] ?? true,
      newFeatureAnnouncements: json['newFeatureAnnouncements'] ?? true,
      tutorialPrompt: json['tutorialPrompt'] ?? true,
      feedbackRequest: json['feedbackRequest'] ?? true,
      announcementBanners: json['announcementBanners'] ?? true,
    );
  }
}
