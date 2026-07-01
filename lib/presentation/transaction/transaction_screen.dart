import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/formatters.dart';
import 'package:kudipay/shared/widgets/shimmer_widget.dart';
import 'package:kudipay/model/transaction/transaction_model.dart';
import 'package:kudipay/presentation/transaction/transaction_filter_screen.dart';
import 'package:kudipay/provider/transaction/transaction_provider.dart';
import 'package:kudipay/provider/refresh/refresh_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load transactions on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionProvider.notifier).loadTransactions(refresh: true);
    });

    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final state = ref.read(transactionProvider);
    // Only fire when near the bottom, not already loading, and more pages exist
    if (!state.isLoading &&
        state.hasMore &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      ref.read(transactionProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final transactionState = ref.watch(transactionProvider);
    final groupedTransactions = ref.watch(groupedTransactionsProvider);

    // Show SnackBar for errors that occur while data already exists
    // (pagination failures, search failures) � not caught by the empty-state UI.
    ref.listen<TransactionState>(transactionProvider, (previous, next) {
      if (next.error != null &&
          next.error != previous?.error &&
          next.transactions.isNotEmpty) {
        _showErrorSnackBar(_friendlyError(next.error!));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildSearchBar(isTablet),
          Expanded(
            child: _buildBody(
              context,
              transactionState,
              groupedTransactions,
              isTablet,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Color(0xFFF9F9F9),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Transactions',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.black),
          onPressed: _handleDownload,
        ),
        IconButton(
          icon: const Icon(Icons.tune, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TransactionFilterScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isTablet) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 12,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (query) {
            ref.read(searchQueryProvider.notifier).state = query;
            ref.read(transactionProvider.notifier).searchTransactions(query);
          },
          decoration: const InputDecoration(
            hintText: 'Search.....',
            hintStyle: TextStyle(
              color: Color(0xFFB0BEC5),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Color(0xFFB0BEC5),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TransactionState state,
    Map<String, List<Transaction>> groupedTransactions,
    bool isTablet,
  ) {
    if (state.isLoading && state.transactions.isEmpty) {
      return const TransactionListShimmer();
    }

    if (state.error != null && state.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _friendlyError(state.error!),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(transactionProvider.notifier)
                    .loadTransactions(refresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF069494),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                label: const Text(
                  'Try Again',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      // Use the central orchestrator so wallet + transactions refresh together.
      // The user sees one unified pull gesture that syncs all data at once.
      onRefresh: () => ref.read(refreshProvider.notifier).refreshAll(),
      color: const Color(0xFF069494),
      child: ListView(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: 8,
        ),
        children: [
          ..._buildTransactionGroups(groupedTransactions, isTablet),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: TransactionListShimmer(itemCount: 3),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildTransactionGroups(
    Map<String, List<Transaction>> grouped,
    bool isTablet,
  ) {
    List<Widget> widgets = [];

    grouped.forEach((dateHeader, transactions) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            dateHeader,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

      for (var transaction in transactions) {
        widgets.add(_buildTransactionCard(transaction, isTablet));
      }
    });

    return widgets;
  }

  Widget _buildTransactionCard(Transaction transaction, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTransactionIcon(transaction, isTablet),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTransactionDetails(transaction, isTablet),
          ),
          const SizedBox(width: 12),
          _buildAmountAndStatus(transaction, isTablet),
        ],
      ),
    );
  }

  Widget _buildTransactionIcon(Transaction transaction, bool isTablet) {
    final isDebit = transaction.type == TransactionType.debit;
    return Container(
      width: isTablet ? 44 : 40,
      height: isTablet ? 44 : 40,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isDebit ? Icons.arrow_upward : Icons.arrow_downward,
        color: const Color(0xFF069494),
        size: 20,
      ),
    );
  }

  Widget _buildTransactionDetails(Transaction transaction, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          transaction.description,
          style: TextStyle(
            fontSize: isTablet ? 15 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          TransactionFormatter.formatDateTime(transaction.date),
          style: TextStyle(
            fontSize: isTablet ? 13 : 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountAndStatus(Transaction transaction, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          transaction.type == TransactionType.debit
              ? '-?${TransactionFormatter.formatAmount(transaction.amount)}'
              : '+?${TransactionFormatter.formatAmount(transaction.amount)}',
          style: TextStyle(
            fontSize: isTablet ? 16 : 15,
            fontWeight: FontWeight.w600,
            color: transaction.type == TransactionType.debit
                ? Colors.black87
                : const Color(0xFF069494),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: _getStatusColor(transaction.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            transaction.status.value,
            style: TextStyle(
              fontSize: isTablet ? 11 : 10,
              color: _getStatusColor(transaction.status),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.successful:
        return const Color(0xFF069494);
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.pending:
        return Colors.orange;
    }
  }

  /// Converts raw exception strings into user-friendly messages.
  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('network') ||
        lower.contains('internet')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (lower.contains('timeout')) {
      return 'The request timed out. Please try again.';
    }
    if (lower.contains('401') || lower.contains('unauthori')) {
      return 'Your session has expired. Please log in again.';
    }
    if (lower.contains('500') || lower.contains('server')) {
      return 'Something went wrong on our end. Please try again later.';
    }
    return 'Something went wrong. Please try again.';
  }

  /// Shows a non-intrusive error banner for pagination / search failures.
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xFFB00020),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => ref
                .read(transactionProvider.notifier)
                .loadTransactions(refresh: true),
          ),
        ),
      );
  }

  Future<void> _handleDownload() async {
    try {
      final url =
          await ref.read(transactionProvider.notifier).downloadTransactions();
      if (!mounted) return;
      if (url != null) {
        // Copy the download URL to clipboard so the user can open it in a browser.
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Download link copied to clipboard'),
              backgroundColor: const Color(0xFF069494),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        _showErrorSnackBar(
            'Could not generate your download. Please try again.');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar(_friendlyError(e.toString()));
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          // Read filter inside the builder so radio buttons always reflect
          // the latest state, even if it changes while the dialog is open.
          final currentFilter = ref.watch(transactionFilterProvider);
          return AlertDialog(
            title: const Text('Filter Transactions'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('All Transactions'),
                  leading: Radio<TransactionStatus?>(
                    value: null,
                    groupValue: currentFilter.status,
                    activeColor: const Color(0xFF069494),
                    onChanged: (val) {
                      ref.read(transactionFilterProvider.notifier).state =
                          currentFilter.copyWith(clearStatus: true);
                      Navigator.pop(dialogContext);
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Successful'),
                  leading: Radio<TransactionStatus?>(
                    value: TransactionStatus.successful,
                    groupValue: currentFilter.status,
                    activeColor: const Color(0xFF069494),
                    onChanged: (val) {
                      ref.read(transactionFilterProvider.notifier).state =
                          currentFilter.copyWith(status: val);
                      Navigator.pop(dialogContext);
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Failed'),
                  leading: Radio<TransactionStatus?>(
                    value: TransactionStatus.failed,
                    groupValue: currentFilter.status,
                    activeColor: const Color(0xFF069494),
                    onChanged: (val) {
                      ref.read(transactionFilterProvider.notifier).state =
                          currentFilter.copyWith(status: val);
                      Navigator.pop(dialogContext);
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Pending'),
                  leading: Radio<TransactionStatus?>(
                    value: TransactionStatus.pending,
                    groupValue: currentFilter.status,
                    activeColor: const Color(0xFF069494),
                    onChanged: (val) {
                      ref.read(transactionFilterProvider.notifier).state =
                          currentFilter.copyWith(status: val);
                      Navigator.pop(dialogContext);
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFF069494)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
