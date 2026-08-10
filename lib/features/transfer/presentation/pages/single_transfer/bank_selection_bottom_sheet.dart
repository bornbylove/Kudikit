import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
// Bank and bankListProvider moved out of this widget: the entity now lives in
// the domain layer and the fetch goes through TransferRepository. Re-exported
// so screens importing this sheet for `Bank` keep resolving.
export 'package:kudipay/features/transfer/domain/entities/bank_entity.dart';

import 'package:kudipay/features/transfer/domain/entities/bank_entity.dart';
import 'package:kudipay/features/transfer/presentation/controllers/transfer_controller.dart';

class BankSelectionBottomSheet extends ConsumerStatefulWidget {
  final Function(Bank) onBankSelected;

  const BankSelectionBottomSheet({
    super.key,
    required this.onBankSelected,
  });

  static void show(BuildContext context,
      {required Function(Bank) onBankSelected}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          BankSelectionBottomSheet(onBankSelected: onBankSelected),
    );
  }

  @override
  ConsumerState<BankSelectionBottomSheet> createState() =>
      _BankSelectionBottomSheetState();
}

class _BankSelectionBottomSheetState
    extends ConsumerState<BankSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Bank> _filteredBanks = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final banksAsync = ref.read(bankListProvider);
        banksAsync.whenData((banks) {
          setState(() => _filteredBanks = banks);
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBanks(String query) {
    final allBanks = ref.read(bankListProvider).when(
          data: (banks) => banks,
          loading: () => <Bank>[],
          error: (_, __) => <Bank>[],
        );
    setState(() {
      if (query.isEmpty) {
        _filteredBanks = allBanks;
      } else {
        _filteredBanks = allBanks
            .where(
                (bank) => bank.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Bank',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 18),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 20),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterBanks,
                decoration: InputDecoration(
                  hintText: 'Search bank',
                  hintStyle: TextStyle(
                    color: Colors.black38,
                    fontSize: AppLayout.fontSize(context, 14),
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryTeal,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 20),
                ),
                itemCount: _filteredBanks.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.grey[200],
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final bank = _filteredBanks[index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: AppLayout.scaleHeight(context, 8),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFF6B35),
                      radius: AppLayout.scaleWidth(context, 20),
                      child: Text(
                        bank.name[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppLayout.fontSize(context, 16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(
                      bank.name,
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 15),
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.black26,
                    ),
                    onTap: () {
                      widget.onBankSelected(bank);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
