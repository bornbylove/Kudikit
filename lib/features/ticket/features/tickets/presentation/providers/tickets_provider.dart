// lib/features/tickets/presentation/providers/tickets_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/ticket_model.dart';
import '../../data/tickets_repository.dart';
// ADD this
import 'package:flutter_riverpod/legacy.dart'; // keep existing

// Repository provider
final ticketsRepositoryProvider = Provider<TicketsRepository>((ref) {
  return TicketsRepository();
});

// Selected tab / active status provider
final selectedTicketStatusProvider =
    StateProvider<TicketStatus>((ref) => TicketStatus.inProgress);

// Filtered tickets based on selected status
final filteredTicketsProvider = Provider<List<TicketModel>>((ref) {
  final repository = ref.watch(ticketsRepositoryProvider);
  final status = ref.watch(selectedTicketStatusProvider);
  return repository.getTicketsByStatus(status);
});

// Count per status (for badge/indicator use)
final ticketCountByStatusProvider =
    Provider.family<int, TicketStatus>((ref, status) {
  final repository = ref.watch(ticketsRepositoryProvider);
  return repository.getTicketsByStatus(status).length;
});
