// lib/features/tickets/data/tickets_repository.dart

import '../../../core/models/ticket_model.dart';

class TicketsRepository {
  static const List<TicketModel> _allTickets = [
    TicketModel(
      id: 'KD - 88675',
      title: 'Failed payment for airtime purchase',
      category: 'Payment',
      updatedAt: '25 mins ago',
      status: TicketStatus.inProgress,
    ),
    TicketModel(
      id: 'KD - 88676',
      title: 'Card transaction declined',
      category: 'Payment',
      updatedAt: '1 hr ago',
      status: TicketStatus.inProgress,
    ),
    TicketModel(
      id: 'KD - 88675',
      title: 'Unauthorized transaction on my account',
      category: 'Payment',
      updatedAt: '25 mins ago',
      status: TicketStatus.opened,
    ),
    TicketModel(
      id: 'KD - 88680',
      title: 'Transfer reversal pending review',
      category: 'Transfer',
      updatedAt: '2 hrs ago',
      status: TicketStatus.opened,
    ),
    TicketModel(
      id: 'KD - 88677',
      title: 'Account verification issue',
      category: 'Account',
      updatedAt: '3 hrs ago',
      status: TicketStatus.work,
    ),
    TicketModel(
      id: 'KD - 88678',
      title: 'Duplicate charge on my account',
      category: 'Payment',
      updatedAt: '5 hrs ago',
      status: TicketStatus.work,
    ),
    TicketModel(
      id: 'KD - 88670',
      title: 'Wrong beneficiary transfer resolved',
      category: 'Transfer',
      updatedAt: '1 day ago',
      status: TicketStatus.resolved,
    ),
    TicketModel(
      id: 'KD - 88671',
      title: 'Account upgrade completed',
      category: 'Account',
      updatedAt: '2 days ago',
      status: TicketStatus.resolved,
    ),
  ];

  List<TicketModel> getTicketsByStatus(TicketStatus status) {
    return _allTickets.where((t) => t.status == status).toList();
  }

  List<TicketModel> getAllTickets() => _allTickets;
}
