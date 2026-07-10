import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/shared/widgets/contact_list_item.dart';
import 'package:kudipay/shared/widgets/recipient_tab.dart';
import 'package:kudipay/features/request/domain/entities/request_model.dart';
import 'package:kudipay/features/request/presentation/pages/select_recipient_screen.dart';

class RequestMoneyMainScreen extends StatefulWidget {
  const RequestMoneyMainScreen({super.key});

  @override
  State<RequestMoneyMainScreen> createState() => _RequestMoneyMainScreenState();
}

class _RequestMoneyMainScreenState extends State<RequestMoneyMainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final Set<String> _selectedContactIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  List<Contact> get _filteredContacts {
    final source = _selectedTabIndex == 0
        ? ContactData.allContacts
        : ContactData.recentContacts;
    if (_searchQuery.isEmpty) return source;
    return source.where((c) {
      return c.name.toLowerCase().contains(_searchQuery) ||
          c.phoneNumber.contains(_searchQuery);
    }).toList();
  }

  void _toggleSelection(Contact contact) {
    setState(() {
      if (_selectedContactIds.contains(contact.id)) {
        _selectedContactIds.remove(contact.id);
      } else {
        _selectedContactIds.add(contact.id);
      }
    });
  }

  bool get _canContinue => _selectedContactIds.isNotEmpty;

  bool get _showContinueButton =>
      _selectedTabIndex == 0 || _selectedTabIndex == 1;

  void _onContinue() {
    final selected = (_selectedTabIndex == 0
            ? ContactData.allContacts
            : ContactData.recentContacts)
        .where((c) => _selectedContactIds.contains(c.id))
        .toList();
    Navigator.push(context,
        MaterialPageRoute(builder: ((context) => SelectRecipientsScreen())));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Requesting from ${selected.map((c) => c.name).join(', ')}',
        ),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onAddRecipient() {
    if (_phoneController.text.trim().length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Adding ${_phoneController.text.trim()} as recipient'),
          backgroundColor: AppColors.primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // ---- App Bar ----
            _buildAppBar(),

            // ---- Main Content Card ----
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildMainCard(screenHeight),
                    const SizedBox(height: 16),

                    // ---- Continue Button ----
                    if (_showContinueButton) _buildContinueButton(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            color: AppColors.textDark,
            onPressed: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Request Money',
                style: AppTextStyles.pageTitle,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMainCard(double screenHeight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ? Replaced custom.SearchBar with a standard TextField-based search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 4),

          // Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: RecipientTabBar(
              selectedIndex: _selectedTabIndex,
              onTabChanged: (index) {
                setState(() {
                  _selectedTabIndex = index;
                  _selectedContactIds.clear();
                  _searchController.clear();
                });
              },
            ),
          ),

          // Tab Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  // ? Inline search bar — no custom import needed
  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.divider.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.contactName,
        decoration: InputDecoration(
          hintText: 'Search contacts',
          hintStyle: AppTextStyles.contactPhone,
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.divider,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildContactTab(key: const ValueKey('contact'));
      case 1:
        return _buildRecentTab(key: const ValueKey('recent'));
      case 2:
        return _buildPhoneTab(key: const ValueKey('phone'));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildContactTab({Key? key}) {
    final contacts = _filteredContacts;
    return KeyedSubtree(
      key: key,
      child: contacts.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No contacts found',
                style: AppTextStyles.label,
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ContactListItemFull(
                  contact: contact,
                  isSelected: _selectedContactIds.contains(contact.id),
                  onTap: () => _toggleSelection(contact),
                );
              },
            ),
    );
  }

  Widget _buildRecentTab({Key? key}) {
    final contacts = _filteredContacts;
    return KeyedSubtree(
      key: key,
      child: contacts.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No recent contacts',
                style: AppTextStyles.label,
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ContactListItemFull(
                  contact: contact,
                  isSelected: _selectedContactIds.contains(contact.id),
                  onTap: () => _toggleSelection(contact),
                );
              },
            ),
    );
  }

  Widget _buildPhoneTab({Key? key}) {
    return KeyedSubtree(
      key: key,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter phone no.',
              style: AppTextStyles.label,
            ),
            const SizedBox(height: 8),

            // Phone number input
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.divider,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))
                ],
                style: AppTextStyles.phoneInput,
                decoration: const InputDecoration(
                  hintText: '+234',
                  hintStyle: AppTextStyles.phoneInput,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (v) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),

            // Add Recipient Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _phoneController.text.trim().length > 4
                    ? _onAddRecipient
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  disabledBackgroundColor:
                      AppColors.primaryTeal.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Add Recipient',
                  style: AppTextStyles.buttonText,
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Center(
              child: Text(
                "If they're not on KudiKit, they'll receive an SMS invitation",
                style: AppTextStyles.footerNote,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _canContinue ? _onContinue : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          disabledBackgroundColor:
              AppColors.primaryTeal.withValues(alpha: 0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'Continue',
          style: AppTextStyles.buttonText,
        ),
      ),
    );
  }
}
