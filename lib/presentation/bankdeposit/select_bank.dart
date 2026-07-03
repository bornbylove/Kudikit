import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/shimmer_widget.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';
import 'package:kudipay/provider/funding/funding_provider.dart';

class SelectBankScreen extends ConsumerStatefulWidget {
  const SelectBankScreen({super.key});

  @override
  ConsumerState<SelectBankScreen> createState() => _SelectBankScreenState();
}

class _SelectBankScreenState extends ConsumerState<SelectBankScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(banksProvider.notifier).loadBanks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Clear search state so stale query doesn't persist when returning to this screen
    ref.read(bankSearchQueryProvider.notifier).state = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banksState = ref.watch(banksProvider);
    final searchQuery = ref.watch(bankSearchQueryProvider);

    // Pure computation off watched state — reacts correctly when either
    // the bank list or the query changes. Previously used ref.read(notifier)
    // which would not recompute when banks updated while search was active.
    final filteredBanks = searchQuery.isEmpty
        ? banksState.banks
        : banksState.banks
            .where(
                (b) => b.name.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      body: _buildBody(context, banksState, filteredBanks),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Select Bank',
        style: TextStyle(
          color: Colors.black,
          fontSize: AppLayout.fontSize(context, 18),
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(
    BuildContext context,
    BanksState banksState,
    List<Bank> filteredBanks,
  ) {
    return Column(
      children: [
        // Search Bar
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 16),
            vertical: AppLayout.scaleHeight(context, 12),
          ),
          child: _buildSearchBar(context),
        ),

        SizedBox(height: AppLayout.scaleHeight(context, 16)),

        // Banks Grid
        Expanded(
          child: _buildBanksList(context, banksState, filteredBanks),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final searchQuery = ref.watch(bankSearchQueryProvider);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 25)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (query) {
          ref.read(bankSearchQueryProvider.notifier).state = query;
        },
        decoration: InputDecoration(
          hintText: 'Search bank',
          hintStyle: TextStyle(
            color: const Color(0xFFB0BEC5),
            fontSize: AppLayout.fontSize(context, 14),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: const Color(0xFFB0BEC5),
            size: AppLayout.scaleWidth(context, 20),
          ),
          // Fix 4: clear button — only shows when there is text
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[500],
                    size: AppLayout.scaleWidth(context, 18),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(bankSearchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 16),
            vertical: AppLayout.scaleHeight(context, 12),
          ),
        ),
      ),
    );
  }

  Widget _buildBanksList(
    BuildContext context,
    BanksState banksState,
    List<Bank> filteredBanks,
  ) {
    if (banksState.isLoading && banksState.banks.isEmpty) {
      return const BankListShimmer();
    }

    if (banksState.error != null && banksState.banks.isEmpty) {
      return _buildErrorView(context, banksState.error!);
    }

    if (filteredBanks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: AppLayout.scaleWidth(context, 64),
              color: Colors.grey[400],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Text(
              'No banks found',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 16),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        AppLayout.scaleWidth(context, 20),
        AppLayout.scaleHeight(context, 8),
        AppLayout.scaleWidth(context, 20),
        AppLayout.scaleHeight(context, 24),
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.78,
        crossAxisSpacing: AppLayout.scaleWidth(context, 12),
        mainAxisSpacing: AppLayout.scaleHeight(context, 20),
      ),
      itemCount: filteredBanks.length,
      itemBuilder: (context, index) {
        final bank = filteredBanks[index];
        return _buildBankItem(context, bank);
      },
    );
  }

  Widget _buildBankItem(BuildContext context, Bank bank) {
    final logoSize = AppLayout.scaleWidth(context, 64);

    return InkWell(
      onTap: () {
        ref.read(selectedBankProvider.notifier).state = bank;
        Navigator.pop(context, bank);
      },
      borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo circle — tries network image, falls back to coloured initials
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color: _getBankColor(bank.logo),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: _buildBankLogo(bank, logoSize),
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 8)),
          Text(
            bank.name,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 12),
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBankLogo(Bank bank, double size) {
    final url = _bankLogoUrl(bank.logo);
    if (url != null) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _bankInitialsWidget(bank),
      );
    }
    return _bankInitialsWidget(bank);
  }

  Widget _bankInitialsWidget(Bank bank) {
    return Center(
      child: Text(
        _getBankInitials(bank.name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String? _bankLogoUrl(String logo) {
    const Map<String, String> logos = {
      'gtbank':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/GTBank_logo.svg/200px-GTBank_logo.svg.png',
      'firstbank':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/First_bank_of_Nigeria_plc_logo.png/200px-First_bank_of_Nigeria_plc_logo.png',
      'wema':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/06/Wema_Bank_Logo.png/200px-Wema_Bank_Logo.png',
      'uba':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/United_Bank_for_Africa_Logo.svg/200px-United_Bank_for_Africa_Logo.svg.png',
      'fcmb':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0a/FCMB_logo.png/200px-FCMB_logo.png',
      'sterling':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Sterling_Bank_Logo.png/200px-Sterling_Bank_Logo.png',
    };
    return logos[logo.toLowerCase()];
  }

  Widget _buildErrorView(BuildContext context, String message) {
    final lower = message.toLowerCase();
    final IconData icon =
        lower.contains('internet') || lower.contains('network')
            ? Icons.wifi_off_rounded
            : lower.contains('timed out') || lower.contains('timeout')
                ? Icons.timer_off_rounded
                : Icons.cloud_off_rounded;

    return Center(
      child: Padding(
        padding: AppLayout.pagePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppLayout.scaleWidth(context, 64),
              color: Colors.grey[400],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Text(
              message,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(banksProvider.notifier).loadBanks();
              },
              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
              label: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF069494),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 32)),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 32),
                  vertical: AppLayout.scaleHeight(context, 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBankColor(String logo) {
    switch (logo.toLowerCase()) {
      case 'gtbank':
        return const Color(0xFFFF6600);
      case 'firstbank':
        return const Color(0xFF002244);
      case 'wema':
        return const Color(0xFF722C7A);
      case 'uba':
        return const Color(0xFFD32F2F);
      case 'fcmb':
        return const Color(0xFF7B1FA2);
      case 'sterling':
        return const Color(0xFFD32F2F);
      case 'parallex':
        return const Color(0xFF1E3A8A);
      case 'globus':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF069494);
    }
  }

  String _getBankInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
}
