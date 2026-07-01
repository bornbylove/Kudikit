import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/kudi_appbar.dart';
import 'package:kudipay/shared/widgets/contact_avatar.dart';
import 'package:kudipay/shared/widgets/contact_list_item.dart';
import 'package:kudipay/shared/widgets/recipient_tab.dart';
import 'package:kudipay/presentation/request/preview_request_screen.dart';
import 'package:kudipay/presentation/request/request_money_screen.dart';
import 'package:kudipay/provider/request/request_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/request/request_model.dart';

class SelectRecipientsScreen extends ConsumerStatefulWidget {
  const SelectRecipientsScreen({super.key});

  @override
  ConsumerState<SelectRecipientsScreen> createState() =>
      _SelectRecipientsScreenState();
}

class _SelectRecipientsScreenState
    extends ConsumerState<SelectRecipientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _searchQuery = '';
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+234';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(requestProvider.notifier).loadRequests();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  List<Contact> _filterContacts(List<Contact> contacts) {
    if (_searchQuery.isEmpty) return contacts;
    return contacts.where((contact) {
      return contact.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          contact.phone.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(requestProvider);
    final selectedCount = provider.selectedContacts.length;

    final List<Contact> tabContacts = _selectedTabIndex == 0
        ? _filterContacts(provider.allContacts)
        : _selectedTabIndex == 1
            ? _filterContacts(provider.recentContacts)
            : [];

    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: KudiAppBar(title: 'Request Money'),
      body: Column(
        children: [
          // -- Search bar ----------------------------------------------
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 16),
              vertical: AppLayout.scaleHeight(context, 8),
            ),
            child: _KudiSearchField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // -- Selected chips ------------------------------------------
          if (selectedCount > 0)
            SizedBox(
              height: AppLayout.scaleHeight(context, 44),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 16),
                ),
                scrollDirection: Axis.horizontal,
                itemCount: provider.selectedContacts.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: AppLayout.scaleWidth(context, 8)),
                itemBuilder: (context, index) {
                  final contact = provider.selectedContacts[index];
                  return _SelectedChip(
                    contact: contact,
                    onRemove: () => ref
                        .read(requestProvider.notifier)
                        .toggleContactSelection(contact),
                  );
                },
              ),
            ),

          SizedBox(height: AppLayout.scaleHeight(context, 12)),

          // -- Tab bar -------------------------------------------------
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 16),
            ),
            child: RecipientTabBar(
              selectedIndex: _selectedTabIndex,
              onTabChanged: (i) => setState(() => _selectedTabIndex = i),
            ),
          ),

          // -- Contact list card ----------------------------------------
          Expanded(
            child: Container(
              margin: EdgeInsets.fromLTRB(
                AppLayout.scaleWidth(context, 16),
                AppLayout.scaleHeight(context, 12),
                AppLayout.scaleWidth(context, 16),
                AppLayout.scaleHeight(context, 12),
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
              ),
              child: _selectedTabIndex == 2
                  ? _PhoneTab(controller: _phoneController)
                  : _ContactListView(
                      contacts: tabContacts,
                      selectedContacts: provider.selectedContacts,
                      onToggle: (contact) => ref
                          .read(requestProvider.notifier)
                          .toggleContactSelection(contact),
                    ),
            ),
          ),
        ],
      ),

      // -- Bottom CTA ---------------------------------------------------
      bottomNavigationBar: _BottomCta(
        selectedCount: selectedCount,
        onContinue: selectedCount > 0
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RequestMoneyScreen(),
                  ),
                )
            : null,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Private sub-widgets
// -----------------------------------------------------------------------------

class _KudiSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const _KudiSearchField({this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.searchBackground,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 10),
            child: Icon(Icons.search, color: AppColors.textGrey, size: 20),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 50, minHeight: 48),
          hintText: 'Search.....',
          hintStyle: AppTextStyles.searchHint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _SelectedChip extends StatelessWidget {
  final Contact contact;
  final VoidCallback onRemove;

  const _SelectedChip({required this.contact, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            contact.name.split(' ').first,
            style: AppTextStyles.contactName,
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

class _ContactListView extends StatelessWidget {
  final List<Contact> contacts;
  final List<Contact> selectedContacts;
  final ValueChanged<Contact> onToggle;

  const _ContactListView({
    required this.contacts,
    required this.selectedContacts,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline,
                size: AppLayout.scaleWidth(context, 64),
                color: AppColors.divider),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
            Text('No contacts found', style: AppTextStyles.label),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 12),
        vertical: AppLayout.scaleHeight(context, 4),
      ),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final isSelected = selectedContacts.any((c) => c.id == contact.id);

        return ContactListItemFull(
          contact: contact,
          isSelected: isSelected,
          onTap: () => onToggle(contact),
        );
      },
    );
  }
}

class _PhoneTab extends StatelessWidget {
  final TextEditingController controller;

  const _PhoneTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter phone no.', style: AppTextStyles.label),
          SizedBox(height: AppLayout.scaleHeight(context, 8)),
          Container(
            decoration: BoxDecoration(
              color: AppColors.searchBackground,
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: AppTextStyles.phoneInput,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
              ),
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        "If they're not on Kudikil, they'll receive an SMS invitation"),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.checkGreen,
                foregroundColor: AppColors.primaryTeal,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                    vertical: AppLayout.scaleHeight(context, 16)),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
                ),
              ),
              child: Text('Add Recipient',
                  style: AppTextStyles.buttonText
                      .copyWith(color: AppColors.primaryTeal)),
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 8)),
          Text(
            "If they're not on Kudikil, they'll receive an SMS invitation",
            style: AppTextStyles.footerNote,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onContinue;

  const _BottomCta({required this.selectedCount, this.onContinue});

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
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            disabledBackgroundColor: AppColors.divider,
            foregroundColor: AppColors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 14)),
            ),
          ),
          child: Text(
            selectedCount > 0
                ? 'Continue with $selectedCount Recipient${selectedCount > 1 ? 's' : ''}'
                : 'Continue',
            style: AppTextStyles.buttonText,
          ),
        ),
      ),
    );
  }
}
