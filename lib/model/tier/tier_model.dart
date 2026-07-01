import 'package:flutter/material.dart';

enum TierLevel {
  basic,
  pro,
  mega,
}

class TierRequirement {
  final String title;
  final bool isCompleted;
  final IconData? icon;

  TierRequirement({
    required this.title,
    required this.isCompleted,
    this.icon,
  });
}

class TierBenefit {
  final String title;
  final String? value;

  TierBenefit({
    required this.title,
    this.value,
  });
}

class UpgradeTier {
  final TierLevel level;
  final String name;
  final String displayName;
  final int tierNumber;
  final Color color;
  final IconData icon;
  final List<TierRequirement> requirements;
  final List<TierBenefit> benefits;
  final double dailySendLimit;
  final double dailyReceiveLimit;
  final double maxBalance;

  UpgradeTier({
    required this.level,
    required this.name,
    required this.displayName,
    required this.tierNumber,
    required this.color,
    required this.icon,
    required this.requirements,
    required this.benefits,
    required this.dailySendLimit,
    required this.dailyReceiveLimit,
    required this.maxBalance,
  });

  static UpgradeTier basicTier() {
    return UpgradeTier(
      level: TierLevel.basic,
      name: 'Basic Tribe',
      displayName: 'Basic Tribe',
      tierNumber: 1,
      color: const Color(0xFF4CAF50),
      icon: Icons.shield_rounded,
      requirements: [
        TierRequirement(
          title: 'Email Verification',
          isCompleted: true,
          icon: Icons.email,
        ),
        TierRequirement(
          title: 'Phone Verification',
          isCompleted: true,
          icon: Icons.phone,
        ),
      ],
      benefits: [
        TierBenefit(title: 'Daily Send Limit', value: '₦50,000'),
        TierBenefit(title: 'Daily Receive Limit', value: '₦200,000'),
        TierBenefit(title: 'Maximum Balance', value: '₦300,000'),
      ],
      dailySendLimit: 50000,
      dailyReceiveLimit: 200000,
      maxBalance: 300000,
    );
  }

  static UpgradeTier proTier() {
    return UpgradeTier(
      level: TierLevel.pro,
      name: 'Pro Tribe',
      displayName: 'Upgrade To Pro Tribe',
      tierNumber: 2,
      color: const Color(0xFFFFA726),
      icon: Icons.star,
      requirements: [
        TierRequirement(
          title: 'NIN / BVN',
          isCompleted: false,
          icon: Icons.credit_card,
        ),
        TierRequirement(
          title: 'Face verification',
          isCompleted: false,
          icon: Icons.face,
        ),
        TierRequirement(
          title: 'Valid ID Card (Front & Back)',
          isCompleted: false,
          icon: Icons.badge,
        ),
      ],
      benefits: [
        TierBenefit(title: 'Daily Send Limit', value: '₦500,000'),
        TierBenefit(title: 'Daily Receive Limit', value: '₦1,000,000'),
        TierBenefit(title: 'Maximum Balance', value: '₦3,000,000'),
      ],
      dailySendLimit: 500000,
      dailyReceiveLimit: 1000000,
      maxBalance: 3000000,
    );
  }

  static UpgradeTier megaTier() {
    return UpgradeTier(
      level: TierLevel.mega,
      name: 'Mega Tribe',
      displayName: 'Upgrade To Mega Tribe',
      tierNumber: 3,
      color: const Color(0xFF9C27B0),
      icon: Icons.workspace_premium,
      requirements: [
        TierRequirement(
          title: 'NIN / BVN',
          isCompleted: false,
          icon: Icons.credit_card,
        ),
        TierRequirement(
          title: 'Face verification',
          isCompleted: false,
          icon: Icons.face,
        ),
        TierRequirement(
          title: 'Valid ID Card (Front & Back)',
          isCompleted: false,
          icon: Icons.badge,
        ),
        TierRequirement(
          title: 'Address Verification (Agent visit)',
          isCompleted: false,
          icon: Icons.location_on,
        ),
        TierRequirement(
          title: 'Utility Bill',
          isCompleted: false,
          icon: Icons.description,
        ),
      ],
      benefits: [
        TierBenefit(title: 'Daily Send Limit', value: '₦3,000,000'),
        TierBenefit(title: 'Daily Receive Limit', value: '₦5,000,000'),
        TierBenefit(title: 'Maximum Balance', value: 'Unlimited'),
      ],
      dailySendLimit: 3000000,
      dailyReceiveLimit: 5000000,
      maxBalance: double.infinity,
    );
  }
}

class UploadDocument {
  final String id;
  final String type;
  final String? filePath;
  final DateTime? uploadedAt;
  final String status; // pending, verified, rejected

  UploadDocument({
    required this.id,
    required this.type,
    this.filePath,
    this.uploadedAt,
    this.status = 'pending',
  });

  UploadDocument copyWith({
    String? id,
    String? type,
    String? filePath,
    DateTime? uploadedAt,
    String? status,
  }) {
    return UploadDocument(
      id: id ?? this.id,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      status: status ?? this.status,
    );
  }
}
