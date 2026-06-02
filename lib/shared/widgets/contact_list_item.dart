import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';

import 'package:kudipay/model/request/request_model.dart';

import 'contact_avatar.dart';

class ContactListItem extends StatelessWidget {
  final Contact contact;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showSelectionCircle;

  const ContactListItem({
    super.key,
    required this.contact,
    this.isSelected = false,
    this.onTap,
    this.showSelectionCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            // Avatar
            ContactAvatar(
              initials: contact.initials,
              backgroundColor: contact.avatarColor,
            ),
            const SizedBox(width: 12),

            // Name and Phone
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    contact.name,
                    style: AppTextStyles.contactName,
                  ),
                  const SizedBox(width: 8),

                  // Status indicator
                  if (contact.status == ContactStatus.onApp)
                    Icon(
                      Icons.check,
                      color: Color(0xFF069494),
                      size: 14,
                    ),
                  if (contact.status == ContactStatus.invite)
                    _InviteBadge(),
                ],
              ),
            ),

            // Phone number row below name is separate
            const Spacer(),

            // Selection circle
            if (showSelectionCircle)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Color(0xFF069494) : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? Color(0xFF069494)
                        : AppColors.divider,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: AppColors.white,
                        size: 14,
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class ContactListItemFull extends StatelessWidget {
  final Contact contact;
  final bool isSelected;
  final VoidCallback? onTap;

  const ContactListItemFull({
    super.key,
    required this.contact,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            // Avatar
            ContactAvatar(
              initials: contact.initials,
              backgroundColor: contact.avatarColor,
            ),
            const SizedBox(width: 12),

            // Name and Phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        contact.name,
                        style: AppTextStyles.contactName,
                      ),
                      const SizedBox(width: 8),
                      if (contact.status == ContactStatus.onApp)
                        Icon(
                          Icons.check,
                          color: Color(0xFF069494),
                          size: 14,
                        ),
                      if (contact.status == ContactStatus.invite)
                        const _InviteBadge(),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    contact.phoneNumber,
                    style: AppTextStyles.contactPhone,
                  ),
                ],
              ),
            ),

            // Selection circle
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Color(0xFF069494) : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Color(0xFF069494)
                      : AppColors.divider,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: AppColors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteBadge extends StatelessWidget {
  const _InviteBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.inviteBadgeBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFF069494).withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        'Invite',
        style: AppTextStyles.inviteText,
      ),
    );
  }
}