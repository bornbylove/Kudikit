import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/shared/widgets/transaction_pin_bottom_sheet.dart';
import 'package:kudipay/features/transfer/presentation/pages/single_transfer/transfer_success_dialogue.dart';
import 'package:kudipay/features/transfer/presentation/controllers/transfer_controller.dart';

// =============================================================================
// PinEntryBottomSheet
// =============================================================================
// Thin wrapper that delegates to TransactionPinBottomSheet.
// All PIN logic (hashing, attempts, lockout) lives in TransactionPinService.
// =============================================================================

class PinEntryBottomSheet extends ConsumerWidget {
  const PinEntryBottomSheet({super.key});

  /// Open the transaction PIN sheet for a P2P transfer.
  static void show(BuildContext context) {
    TransactionPinBottomSheet.show(
      context,
      title: 'Enter Transaction PIN',
      subtitle: 'Authorise this transfer with your 4-digit PIN.',
      onSuccess: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const TransactionSuccessBottomSheet()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TransactionPinBottomSheet(
      title: 'Enter Transaction PIN',
      subtitle: 'Authorise this transfer with your 4-digit PIN.',
      onSuccess: () async {
        await ref
            .read(p2pTransferProvider.notifier)
            .processTransfer('verified');
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const TransactionSuccessBottomSheet()),
          );
        }
      },
    );
  }
}
