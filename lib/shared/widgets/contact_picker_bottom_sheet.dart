// ============================================================================
// lib/formatting/widget/contact_picker_bottom_sheet.dart
//
// A full-featured contact picker bottom sheet for the airtime/data flows.
//
// States handled:
//   1. Loading    — spinner while contacts fetch + filter runs
//   2. Permission denied  — explanation + "Grant Access" button
//   3. Permanently denied — explanation + "Open Settings" button
//   4. Empty (no Nigerian numbers found) — friendly empty state
//   5. Results   — searchable, scrollable list with alphabet index
//
// Features:
//   • Real-time search (name or number)
//   • Network logo shown next to each number
//   • Multi-number contacts: shows all Nigerian numbers, user picks one
//   • Alphabet scroll index on right edge for fast navigation
//   • Sticky section headers (A, B, C...)
//   • Returns a NigerianPhoneNumber when user selects
// ============================================================================

import 'package:flutter/material.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/network_logo.dart';
import 'package:kudipay/shared/widgets/shimmer_widget.dart';
import 'package:kudipay/services/contact_service.dart';

// ============================================================================
// Public entry point
// Call this from _pickFromContacts() in phone screens.
// Returns the selected NigerianPhoneNumber, or null if dismissed.
// ============================================================================

Future<NigerianPhoneNumber?> showContactPicker(BuildContext context) {
  return showModalBottomSheet<NigerianPhoneNumber>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ContactPickerBottomSheet(),
  );
}

// ============================================================================
// _ContactPickerBottomSheet
// ============================================================================

class _ContactPickerBottomSheet extends StatefulWidget {
  const _ContactPickerBottomSheet();

  @override
  State<_ContactPickerBottomSheet> createState() =>
      _ContactPickerBottomSheetState();
}

class _ContactPickerBottomSheetState extends State<_ContactPickerBottomSheet> {
  // ── State ────────────────────────────────────────────────────────────────
  _PickerState _pickerState = _PickerState.loading;
  List<NigerianContact> _allContacts = [];
  List<NigerianContact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Alphabet index letters extracted from loaded contacts
  List<String> _indexLetters = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Data Loading ──────────────────────────────────────────────────────────

  Future<void> _loadContacts() async {
    setState(() => _pickerState = _PickerState.loading);

    // 1. Check / request permission
    var permStatus = await ContactService.instance.checkPermission();

    if (permStatus == ContactPermissionStatus.denied) {
      permStatus = await ContactService.instance.requestPermission();
    }

    if (permStatus == ContactPermissionStatus.permanentlyDenied ||
        permStatus == ContactPermissionStatus.restricted) {
      if (mounted)
        setState(() => _pickerState = _PickerState.permanentlyDenied);
      return;
    }

    if (permStatus == ContactPermissionStatus.denied) {
      if (mounted) setState(() => _pickerState = _PickerState.denied);
      return;
    }

    // 2. Permission granted — fetch + filter contacts
    try {
      final contacts = await ContactService.instance.getNigerianContacts();

      if (!mounted) return;

      if (contacts.isEmpty) {
        setState(() => _pickerState = _PickerState.empty);
        return;
      }

      // Extract unique first letters for the alphabet index
      final letters = contacts.map((c) => c.indexLetter).toSet().toList()
        ..sort();

      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
        _indexLetters = letters;
        _pickerState = _PickerState.loaded;
      });
    } catch (e) {
      if (mounted) setState(() => _pickerState = _PickerState.error);
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() => _filteredContacts = _allContacts);
      return;
    }

    setState(() {
      _filteredContacts = _allContacts.where((contact) {
        // Match on name
        if (contact.displayName.toLowerCase().contains(query)) return true;
        // Match on any Nigerian number (stripped of spaces)
        return contact.nigerianNumbers.any((n) =>
            n.normalizedNumber.contains(query) ||
            n.displayNumber.replaceAll(' ', '').contains(query));
      }).toList();
    });
  }

  // ── Alphabet Index Navigation ─────────────────────────────────────────────

  void _scrollToLetter(String letter) {
    // Fix 6: guard against the controller not yet having a scroll position
    if (!_scrollController.hasClients) return;

    // Find the first contact with this index letter
    final index = _filteredContacts.indexWhere(
      (c) => c.indexLetter == letter,
    );
    if (index == -1) return;

    // Approximate scroll position: each list item is ~72px
    // Section headers add ~40px each
    // This is an approximation — good enough for quick navigation
    const itemHeight = 72.0;
    const headerHeight = 40.0;

    double offset = 0;
    String? currentLetter;
    for (int i = 0; i < index; i++) {
      if (_filteredContacts[i].indexLetter != currentLetter) {
        currentLetter = _filteredContacts[i].indexLetter;
        offset += headerHeight;
      }
      // Multi-number contacts are taller
      final numCount = _filteredContacts[i].nigerianNumbers.length;
      offset += numCount > 1 ? itemHeight * numCount : itemHeight;
    }

    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  // ── Selection ─────────────────────────────────────────────────────────────

  void _selectNumber(NigerianPhoneNumber number) {
    Navigator.pop(context, number);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.88, // 88% of screen
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 20),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      size: 24, color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(width: 16),
                Text(
                  'Select Contact',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 18),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                // Contact count badge (when loaded)
                if (_pickerState == _PickerState.loaded)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_filteredContacts.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF069494),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Search bar (only shown when contacts are loaded) ────────────
          if (_pickerState == _PickerState.loaded) ...[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 20),
              ),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search name or number...',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF9E9E9E),
                      size: 20,
                    ),
                    // Fix 4: clear button — matches the pattern from select_bank.dart
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              // _onSearchChanged fires via the listener,
                              // but we also call setState to hide the icon
                              setState(() {});
                            },
                            child: const Icon(
                              Icons.clear,
                              color: Color(0xFF9E9E9E),
                              size: 18,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
          ],

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_pickerState) {
      case _PickerState.loading:
        return _buildLoading();
      case _PickerState.denied:
        return _buildPermissionDenied();
      case _PickerState.permanentlyDenied:
        return _buildPermanentlyDenied();
      case _PickerState.empty:
        return _buildEmpty();
      case _PickerState.error:
        return _buildError();
      case _PickerState.loaded:
        return _buildContactList();
    }
  }

  // ── Loading state ──────────────────────────────────────────────────────────

  Widget _buildLoading() {
    // Fix 1: ContactListShimmer replaces the spinner — matches the exact
    // row layout (avatar + name/number) so the transition to real data is
    // seamless. Fix 5: removed misleading "Filtering to Nigerian numbers only"
    // subtitle — this state also covers the permission-check phase.
    return const ContactListShimmer(itemCount: 10);
  }

  // ── Permission denied state ─────────────────────────────────────────────

  Widget _buildPermissionDenied() {
    return Padding(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 32)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.contacts_outlined,
              color: Color(0xFF069494),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Access your contacts',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 18),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'KudiPay needs access to your contacts so you can quickly select who to send airtime or data to.',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              color: const Color(0xFF9E9E9E),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _loadContacts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF069494),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'Grant Access',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 15),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Permanently denied state ───────────────────────────────────────────────

  Widget _buildPermanentlyDenied() {
    return Padding(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 32)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.no_accounts_outlined,
              color: Colors.orange.shade600,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Contacts access blocked',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 18),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'You\'ve previously blocked KudiPay from accessing your contacts. To enable it, open your device Settings and grant Contacts permission.',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              color: const Color(0xFF9E9E9E),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                await ContactService.instance.openSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF069494),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'Open Settings',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 15),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Enter number manually',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Padding(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 32)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person_search_outlined,
              color: Color(0xFF9E9E9E),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Nigerian contacts found',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 17),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'None of your saved contacts have a Nigerian mobile number. Add contacts with Nigerian numbers (e.g. 0803 456 0109) and try again.',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: const Color(0xFF9E9E9E),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF069494), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'Enter number manually',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 15),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF069494),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Padding(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 32)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 16),
          Text(
            'Failed to load contacts',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Something went wrong while reading your contacts. Please try again.',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: const Color(0xFF9E9E9E),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadContacts,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF069494),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
            ),
            child: Text(
              'Try again',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact list ──────────────────────────────────────────────────────────

  Widget _buildContactList() {
    // Empty search results
    if (_filteredContacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 48, color: Color(0xFFBDBDBD)),
              const SizedBox(height: 16),
              Text(
                'No contacts match "${_searchController.text}"',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: const Color(0xFF9E9E9E),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        // ── Main scrollable list ─────────────────────────────────────────
        Expanded(
          child: _buildSectionedList(),
        ),

        // ── Alphabet index (right edge) ──────────────────────────────────
        // Only show when not in search mode (search breaks the alphabetical order)
        if (_searchController.text.isEmpty)
          _AlphabetIndex(
            letters: _indexLetters,
            onLetterTap: _scrollToLetter,
          ),
      ],
    );
  }

  Widget _buildSectionedList() {
    // Build a flat list of items (section headers + contact tiles)
    final List<_ListItem> items = [];
    String? currentLetter;

    for (final contact in _filteredContacts) {
      // Insert section header when the letter changes
      if (_searchController.text.isEmpty &&
          contact.indexLetter != currentLetter) {
        currentLetter = contact.indexLetter;
        items.add(_ListItem.header(currentLetter));
      }
      items.add(_ListItem.contact(contact));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isHeader) {
          return _SectionHeader(letter: item.letter!);
        }
        return _ContactTile(
          contact: item.contact!,
          onSelect: _selectNumber,
        );
      },
    );
  }
}

// ============================================================================
// _ListItem — union type for list rows
// ============================================================================

class _ListItem {
  final bool isHeader;
  final String? letter;
  final NigerianContact? contact;

  const _ListItem._({required this.isHeader, this.letter, this.contact});

  factory _ListItem.header(String letter) =>
      _ListItem._(isHeader: true, letter: letter);

  factory _ListItem.contact(NigerianContact contact) =>
      _ListItem._(isHeader: false, contact: contact);
}

// ============================================================================
// _SectionHeader
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String letter;
  const _SectionHeader({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      color: const Color(0xFFF8F9FA),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 13),
          fontWeight: FontWeight.w700,
          color: const Color(0xFF069494),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ============================================================================
// _ContactTile
// One row per contact. If contact has multiple Nigerian numbers,
// each number is shown as its own tappable sub-row.
// ============================================================================

class _ContactTile extends StatelessWidget {
  final NigerianContact contact;
  final ValueChanged<NigerianPhoneNumber> onSelect;

  const _ContactTile({required this.contact, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final hasSingleNumber = contact.nigerianNumbers.length == 1;

    // Single number — the whole tile is tappable
    if (hasSingleNumber) {
      final number = contact.nigerianNumbers.first;
      return InkWell(
        onTap: () => onSelect(number),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              _ContactAvatar(name: contact.displayName),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        // Fix 2: network is nullable — guard before passing to NetworkLogo
                        if (number.network != null) ...[
                          NetworkLogo(network: number.network!, size: 16),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          number.displayNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: Color(0xFFBDBDBD)),
            ],
          ),
        ),
      );
    }

    // Multiple numbers — show contact name + each number as its own row
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contact name header (not tappable)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              _ContactAvatar(name: contact.displayName),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  contact.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Each number as a tappable sub-row
        ...contact.nigerianNumbers.map((number) {
          return InkWell(
            onTap: () => onSelect(number),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(54, 6, 20, 6),
              child: Row(
                children: [
                  // Fix 2: network is nullable — guard before passing to NetworkLogo
                  if (number.network != null) ...[
                    NetworkLogo(network: number.network!, size: 18),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          number.displayNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          number.network != null
                              ? '${number.network!.displayName} • ${number.label}'
                              : number.label,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 16, color: Color(0xFFBDBDBD)),
                ],
              ),
            ),
          );
        }),
        const Divider(height: 1, indent: 20, color: Color(0xFFF0F0F0)),
      ],
    );
  }
}

// ============================================================================
// _ContactAvatar
// Generates a colored circle with the contact's initials.
// Color is deterministic based on the name so it's consistent across sessions.
// ============================================================================

class _ContactAvatar extends StatelessWidget {
  final String name;
  const _ContactAvatar({required this.name});

  // 8 pleasant colors that work well on white backgrounds
  static const _colors = [
    Color(0xFF4CAF8A),
    Color(0xFF5C6BC0),
    Color(0xFFFF7043),
    Color(0xFF26A69A),
    Color(0xFFAB47BC),
    Color(0xFF42A5F5),
    Color(0xFFEC407A),
    Color(0xFF8D6E63),
  ];

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    // Fix 3: guard against empty name — codeUnits.first throws RangeError on ''
    final color = name.isEmpty
        ? _colors[0]
        : _colors[name.codeUnits.first % _colors.length];

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ============================================================================
// _AlphabetIndex
// Right-edge letter strip for fast alphabetical navigation.
// ============================================================================

class _AlphabetIndex extends StatelessWidget {
  final List<String> letters;
  final ValueChanged<String> onLetterTap;

  const _AlphabetIndex({
    required this.letters,
    required this.onLetterTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Allow drag scrolling through the index
      onVerticalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final localY = box.globalToLocal(details.globalPosition).dy;
        final itemHeight = box.size.height / letters.length;
        final index =
            (localY / itemHeight).floor().clamp(0, letters.length - 1);
        onLetterTap(letters[index]);
      },
      child: Container(
        width: 24,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: letters.map((letter) {
            return GestureDetector(
              onTap: () => onLetterTap(letter),
              child: SizedBox(
                height: 18,
                child: Center(
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF069494),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ============================================================================
// Internal state enum
// ============================================================================

enum _PickerState {
  loading,
  denied,
  permanentlyDenied,
  empty,
  error,
  loaded,
}
