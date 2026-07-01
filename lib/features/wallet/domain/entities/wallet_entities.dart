// lib/features/wallet/domain/entities/wallet_entities.dart
//
// Pure Dart domain entities — no Flutter, no JSON, no package imports.

// =============================================================================
// WalletEntity
// =============================================================================

class WalletEntity {
  final double balance;
  final String accountNumber;
  final String accountName;
  final String bankName;
  final DateTime? lastUpdated;

  const WalletEntity({
    this.balance = 0.0,
    this.accountNumber = '',
    this.accountName = '',
    this.bankName = 'KudiPay MFB',
    this.lastUpdated,
  });

  /// Formatted balance string e.g. "50,000.00"
  String get formattedBalance {
    final parts = balance.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final decimal = parts[1];
    final result = StringBuffer();
    int count = 0;
    for (int i = whole.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write(',');
      result.write(whole[i]);
      count++;
    }
    return '${result.toString().split('').reversed.join('')}.$decimal';
  }

  /// Two-letter initials derived from accountName.
  String get initials {
    final parts = accountName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'KK';
  }

  WalletEntity copyWith({
    double? balance,
    String? accountNumber,
    String? accountName,
    String? bankName,
    DateTime? lastUpdated,
  }) =>
      WalletEntity(
        balance: balance ?? this.balance,
        accountNumber: accountNumber ?? this.accountNumber,
        accountName: accountName ?? this.accountName,
        bankName: bankName ?? this.bankName,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

// =============================================================================
// FundingOption
// =============================================================================

enum FundingType {
  bankTransfer,
  cashDeposit,
  cardTopUp,
  ussdTransfer,
  qrCode,
}

class FundingOptionEntity {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final FundingType type;

  const FundingOptionEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
  });
}

// =============================================================================
// VirtualAccountEntity
// =============================================================================

class VirtualAccountEntity {
  final String accountNumber;
  final String accountName;
  final String bankName;
  final String? referenceCode;

  const VirtualAccountEntity({
    required this.accountNumber,
    required this.accountName,
    required this.bankName,
    this.referenceCode,
  });
}
