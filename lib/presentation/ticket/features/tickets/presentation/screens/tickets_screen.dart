// lib/features/tickets/presentation/screens/tickets_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/tickets_provider.dart';
import '../widgets/ticket_card.dart';
import '../widgets/ticket_status_filter.dart';
import '../widgets/empty_tickets_state.dart';

class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(filteredTicketsProvider);
    final screenSize = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
            ),
          ),
        ),
        title: const Text('Tickets'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top spacing
          const SizedBox(height: 12),

          // Filter chips
          const TicketStatusFilter(),

          const SizedBox(height: 12),

          // Ticket list
          Expanded(
            child: tickets.isEmpty
                ? const EmptyTicketsState()
                : ListView.builder(
                    padding: EdgeInsets.only(
                      top: 4,
                      bottom: MediaQuery.paddingOf(context).bottom + 16,
                    ),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return TicketCard(
                        ticket: ticket,
                        onTap: () {
                          // Navigate to ticket detail
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opening ticket: ${ticket.id}'),
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
