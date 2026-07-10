import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/shared/widgets/transaction_pin_bottom_sheet.dart';
import 'package:kudipay/features/transfer/presentation/controllers/transfer_controller.dart';

// =============================================================================
// BulkTransferPinDialog
// =============================================================================
// Delegates to the shared TransactionPinBottomSheet for consistency.
// =============================================================================

class BulkTransferPinDialog extends ConsumerWidget {
  const BulkTransferPinDialog({super.key});

  static void show(BuildContext context, {required VoidCallback onSuccess}) {
    TransactionPinBottomSheet.show(
      context,
      title: 'Authorise Bulk Transfer',
      subtitle: 'Enter your 4-digit transaction PIN to proceed.',
      onSuccess: onSuccess,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TransactionPinBottomSheet(
      title: 'Authorise Bulk Transfer',
      subtitle: 'Enter your 4-digit transaction PIN to proceed.',
      onSuccess: () async {
        await ref.read(bulkTransferProvider.notifier).executeBulkTransfer();
        // PIN verified locally by TransactionPinBottomSheet — no pin arg needed
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}
