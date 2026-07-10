// lib/presentation/request/preview_request_screen.dart
//
// Covers two states shown in the designs:
//   1. Preview state  � shows amount card, recipient, delivery method,
//                       request details, "Send Request" + "Edit Request" CTAs.
//   2. Sent state     � success tick, confirmation copy, delivery method,
//                       recipient list, "Done" CTA.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/kudi_appbar.dart';
import 'package:kudipay/shared/widgets/contact_avatar.dart';
import 'package:kudipay/features/request/domain/entities/request_model.dart';
import 'package:kudipay/features/request/presentation/controllers/request_provider.dart';

class PreviewRequestScreen extends ConsumerStatefulWidget {
  const PreviewRequestScreen({super.key});

  @override
  ConsumerState<PreviewRequestScreen> createState() =>
      _PreviewRequestScreenState();
}

class _PreviewRequestScreenState extends ConsumerState<PreviewRequestScreen> {
  bool _requestSent = false;

  void _sendRequest() {
    setState(() => _requestSent = true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(requestProvider);
    final recipients = provider.selectedContacts;

    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: KudiAppBar(title: 'Preview Request'),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _requestSent
            ? _RequestSentView(recipients: recipients)
            : _PreviewView(
                recipients: recipients,
                onSend: _sendRequest,
                onEdit: () => Navigator.pop(context),
              ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// STATE 1 � Preview
// -----------------------------------------------------------------------------

class _PreviewView extends StatelessWidget {
  final List<Contact> recipients;
  final VoidCallback onSend;
  final VoidCallback onEdit;

  const _PreviewView({
    required this.recipients,
    required this.onSend,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('preview'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 16),
              vertical: AppLayout.scaleHeight(context, 8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -- Amount card ----------------------------------------
                _AmountCard(),

                SizedBox(height: AppLayout.scaleHeight(context, 20)),

                // -- Recipients -----------------------------------------
                ...recipients.map(
                  (contact) => _RecipientRow(contact: contact),
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 20)),

                // -- Delivery method ------------------------------------
                _SectionLabel(label: 'Delivery method'),
                SizedBox(height: AppLayout.scaleHeight(context, 8)),
                _DeliveryMethodCard(recipientCount: recipients.length),

                SizedBox(height: AppLayout.scaleHeight(context, 20)),

                // -- Request details ------------------------------------
                _SectionLabel(label: 'Request Details'),
                SizedBox(height: AppLayout.scaleHeight(context, 8)),
                _RequestDetailsCard(),

                SizedBox(height: AppLayout.scaleHeight(context, 32)),
              ],
            ),
          ),
        ),

        // -- Bottom CTAs ----------------------------------------------
        _PreviewBottomBar(onSend: onSend, onEdit: onEdit),
      ],
    );
  }
}

class _AmountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requesting',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: AppColors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 6)),
          Text(
            '?10,000.00',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 28),
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontFamily: 'PolySans',
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 10)),
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: AppColors.white.withValues(alpha: 0.8),
                size: AppLayout.scaleWidth(context, 14),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 6)),
              Text(
                'Rent',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 13),
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecipientRow extends StatelessWidget {
  final Contact contact;
  const _RecipientRow({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.symmetric(vertical: AppLayout.scaleHeight(context, 4)),
      child: Row(
        children: [
          ContactAvatar(
            initials: contact.initials,
            backgroundColor: contact.avatarColor,
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(contact.name, style: AppTextStyles.contactName),
                    SizedBox(width: AppLayout.scaleWidth(context, 6)),
                    if (contact.status == ContactStatus.onApp)
                      Icon(
                        Icons.check,
                        color: AppColors.primaryTeal,
                        size: AppLayout.scaleWidth(context, 14),
                      ),
                  ],
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 2)),
                Text(contact.phoneNumber, style: AppTextStyles.contactPhone),
              ],
            ),
          ),
          Text(
            '?10,000.00',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: AppLayout.fontSize(context, 13),
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
    );
  }
}

class _DeliveryMethodCard extends StatelessWidget {
  final int recipientCount;
  const _DeliveryMethodCard({required this.recipientCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.backgroundGreen,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: AppLayout.scaleWidth(context, 40),
            height: AppLayout.scaleWidth(context, 40),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal,
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
            ),
            child: Icon(
              Icons.phone_android_outlined,
              color: AppColors.white,
              size: AppLayout.scaleWidth(context, 20),
            ),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'In-App Notification',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 2)),
              Text(
                '$recipientCount recipient${recipientCount > 1 ? 's' : ''} will receive an instant notification',
                style: AppTextStyles.contactPhone,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestDetailsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DetailRow(
          label: 'Category',
          value: 'Transportation',
          trailing: null,
        ),
        _Divider(),
        _DetailRow(
          label: 'Due date',
          value: 'Today',
          trailing: Icons.calendar_today_outlined,
        ),
        _Divider(),
        _DetailRow(
          label: 'Privacy',
          value: 'Private',
          trailing: Icons.lock_outline,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? trailing;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.symmetric(vertical: AppLayout.scaleHeight(context, 12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label),
          Row(
            children: [
              if (trailing != null) ...[
                Icon(trailing,
                    size: AppLayout.scaleWidth(context, 14),
                    color: AppColors.textDark),
                SizedBox(width: AppLayout.scaleWidth(context, 4)),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 13),
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.divider);
}

class _PreviewBottomBar extends StatelessWidget {
  final VoidCallback onSend;
  final VoidCallback onEdit;

  const _PreviewBottomBar({required this.onSend, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppLayout.scaleWidth(context, 16),
        AppLayout.scaleHeight(context, 12),
        AppLayout.scaleWidth(context, 16),
        AppLayout.scaleHeight(context, 24),
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundScreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Send Request � filled teal
            SizedBox(
              width: double.infinity,
              height: AppLayout.scaleHeight(context, 54),
              child: ElevatedButton(
                onPressed: onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 28)),
                  ),
                ),
                child: Text('Send Request', style: AppTextStyles.buttonText),
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 10)),

            // Edit Request � outlined
            SizedBox(
              width: double.infinity,
              height: AppLayout.scaleHeight(context, 54),
              child: OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryTeal,
                  side:
                      const BorderSide(color: AppColors.primaryTeal, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 28)),
                  ),
                ),
                child: Text(
                  'Edit Request',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 15),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// STATE 2 � Request Sent
// -----------------------------------------------------------------------------

class _RequestSentView extends StatelessWidget {
  final List<Contact> recipients;
  const _RequestSentView({required this.recipients});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('sent'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 16),
              vertical: AppLayout.scaleHeight(context, 24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -- Success icon + copy --------------------------------
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: AppLayout.scaleWidth(context, 64),
                        height: AppLayout.scaleWidth(context, 64),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryTeal,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: AppColors.white,
                          size: AppLayout.scaleWidth(context, 30),
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 16)),
                      Text(
                        'Request Sent!',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 20),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          fontFamily: 'PolySans',
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 8)),
                      Text(
                        'Your money request has been sent to '
                        '${recipients.length} person${recipients.length > 1 ? 's' : ''}',
                        style: AppTextStyles.label.copyWith(
                          fontSize: AppLayout.fontSize(context, 13),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 32)),

                // -- Delivery method ------------------------------------
                _SectionLabel(label: 'Delivery method'),
                SizedBox(height: AppLayout.scaleHeight(context, 10)),
                _DeliveryMethodCard(recipientCount: recipients.length),

                SizedBox(height: AppLayout.scaleHeight(context, 24)),

                // -- Recipients -----------------------------------------
                _SectionLabel(label: 'Recipients'),
                SizedBox(height: AppLayout.scaleHeight(context, 10)),
                ...recipients.map(
                  (contact) => _SentRecipientRow(contact: contact),
                ),
              ],
            ),
          ),
        ),

        // -- Done button ----------------------------------------------
        _SentBottomBar(),
      ],
    );
  }
}

class _SentRecipientRow extends StatelessWidget {
  final Contact contact;
  const _SentRecipientRow({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppLayout.scaleHeight(context, 12)),
      child: Row(
        children: [
          ContactAvatar(
            initials: contact.initials,
            backgroundColor: contact.avatarColor,
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(contact.name, style: AppTextStyles.contactName),
              SizedBox(height: AppLayout.scaleHeight(context, 2)),
              Text(
                contact.status == ContactStatus.onApp
                    ? 'Notified via app'
                    : 'Notified via SMS',
                style: AppTextStyles.contactPhone,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SentBottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppLayout.scaleWidth(context, 16),
        AppLayout.scaleHeight(context, 12),
        AppLayout.scaleWidth(context, 16),
        AppLayout.scaleHeight(context, 24),
      ),
      color: AppColors.backgroundScreen,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: AppLayout.scaleHeight(context, 54),
          child: ElevatedButton(
            onPressed: () {
              // Pop back to home
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 28)),
              ),
            ),
            child: Text('Done', style: AppTextStyles.buttonText),
          ),
        ),
      ),
    );
  }
}
