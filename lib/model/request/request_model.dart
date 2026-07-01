import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';

enum RequestStatus {
  pending,
  paid,
  expired,
  partial,
  declined,
}

enum DeliveryMethod {
  inAppNotification,
  sms,
  email,
}

// ✅ Defined here so it's accessible across all files
enum ContactStatus {
  onApp,
  invite,
}

class MoneyRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterPhone;
  final String? requesterAvatar;
  final double amount;
  final String? reason;
  final String category;
  final String? description;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isPrivate;
  final RequestStatus status;
  final double? paidAmount;
  final DateTime? paidAt;
  final List<String> recipientIds;
  final DeliveryMethod deliveryMethod;

  MoneyRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterPhone,
    this.requesterAvatar,
    required this.amount,
    this.reason,
    required this.category,
    this.description,
    required this.createdAt,
    this.dueDate,
    this.isPrivate = true,
    this.status = RequestStatus.pending,
    this.paidAmount,
    this.paidAt,
    required this.recipientIds,
    this.deliveryMethod = DeliveryMethod.inAppNotification,
  });

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status == RequestStatus.pending;
  }

  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate!).inDays;
  }

  double get remainingAmount {
    if (paidAmount == null) return amount;
    return amount - paidAmount!;
  }

  String get statusText {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.paid:
        return 'Paid';
      case RequestStatus.expired:
        return 'Expired';
      case RequestStatus.partial:
        return 'Partial';
      case RequestStatus.declined:
        return 'Declined';
    }
  }

  Color get statusColor {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.paid:
        return Colors.green;
      case RequestStatus.expired:
        return Colors.red;
      case RequestStatus.partial:
        return Colors.blue;
      case RequestStatus.declined:
        return Colors.grey;
    }
  }

  MoneyRequest copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? requesterPhone,
    String? requesterAvatar,
    double? amount,
    String? reason,
    String? category,
    String? description,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isPrivate,
    RequestStatus? status,
    double? paidAmount,
    DateTime? paidAt,
    List<String>? recipientIds,
    DeliveryMethod? deliveryMethod,
  }) {
    return MoneyRequest(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterPhone: requesterPhone ?? this.requesterPhone,
      requesterAvatar: requesterAvatar ?? this.requesterAvatar,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      category: category ?? this.category,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isPrivate: isPrivate ?? this.isPrivate,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      paidAt: paidAt ?? this.paidAt,
      recipientIds: recipientIds ?? this.recipientIds,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterPhone': requesterPhone,
      'requesterAvatar': requesterAvatar,
      'amount': amount,
      'reason': reason,
      'category': category,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isPrivate': isPrivate,
      'status': status.toString(),
      'paidAmount': paidAmount,
      'paidAt': paidAt?.toIso8601String(),
      'recipientIds': recipientIds,
      'deliveryMethod': deliveryMethod.toString(),
    };
  }

  factory MoneyRequest.fromJson(Map<String, dynamic> json) {
    return MoneyRequest(
      id: json['id'],
      requesterId: json['requesterId'],
      requesterName: json['requesterName'],
      requesterPhone: json['requesterPhone'],
      requesterAvatar: json['requesterAvatar'],
      amount: json['amount'].toDouble(),
      reason: json['reason'],
      category: json['category'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isPrivate: json['isPrivate'] ?? true,
      status: RequestStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => RequestStatus.pending,
      ),
      paidAmount: json['paidAmount']?.toDouble(),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      recipientIds: List<String>.from(json['recipientIds']),
      deliveryMethod: DeliveryMethod.values.firstWhere(
        (e) => e.toString() == json['deliveryMethod'],
        orElse: () => DeliveryMethod.inAppNotification,
      ),
    );
  }
}

class Contact {
  final String id;
  final String name;
  final String phone;
  final String? avatar;
  final ContactStatus status;
  final Color avatarColor;
  final bool isInvited;
  final bool isVerified;

  const Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.avatarColor,
    this.avatar,
    this.isInvited = false,
    this.isVerified = true,
  });

  // ✅ phoneNumber getter — widgets using contact.phoneNumber will work
  String get phoneNumber => phone;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  Contact copyWith({
    String? id,
    String? name,
    String? phone,
    String? avatar,
    ContactStatus? status,
    Color? avatarColor,
    bool? isInvited,
    bool? isVerified,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      avatarColor: avatarColor ?? this.avatarColor,
      isInvited: isInvited ?? this.isInvited,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

// Sample data matching the design
class ContactData {
  static final List<Contact> allContacts = [
    const Contact(
      id: '1',
      name: 'Kemi Alabi',
      phone: '+2348031234567',
      status: ContactStatus.onApp,
      avatarColor: AppColors.avatarTeal,
    ),
    const Contact(
      id: '2',
      name: 'Asuquo Michael',
      phone: '+2348051234567',
      status: ContactStatus.onApp,
      avatarColor: AppColors.avatarDark,
    ),
    const Contact(
      id: '3',
      name: 'Ameachi Uche',
      phone: '+2348091234567',
      status: ContactStatus.invite,
      avatarColor: AppColors.avatarBlue,
    ),
    const Contact(
      id: '4',
      name: 'Paul Adegoke',
      phone: '+2349011234567',
      status: ContactStatus.invite,
      avatarColor: AppColors.avatarLightBlue,
    ),
    const Contact(
      id: '5',
      name: 'Tega Ibrahim',
      phone: '+2348071234567',
      status: ContactStatus.onApp,
      avatarColor: AppColors.avatarRed,
    ),
    const Contact(
      id: '6',
      name: 'Victor Obisi',
      phone: '+2348061234567',
      status: ContactStatus.onApp,
      avatarColor: AppColors.avatarOrange,
    ),
  ];

  static final List<Contact> recentContacts = [
    allContacts[0], // Kemi Alabi
    allContacts[1], // Asuquo Michael
    allContacts[5], // Victor Obisi
  ];
}
