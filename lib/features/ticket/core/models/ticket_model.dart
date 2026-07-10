// lib/core/models/ticket_model.dart

enum TicketStatus { inProgress, opened, work, resolved }

extension TicketStatusExtension on TicketStatus {
  String get label {
    switch (this) {
      case TicketStatus.inProgress:
        return 'In Progess';
      case TicketStatus.opened:
        return 'Opened';
      case TicketStatus.work:
        return 'Work';
      case TicketStatus.resolved:
        return 'Resolved';
    }
  }
}

class TicketModel {
  final String id;
  final String title;
  final String category;
  final String updatedAt;
  final TicketStatus status;

  const TicketModel({
    required this.id,
    required this.title,
    required this.category,
    required this.updatedAt,
    required this.status,
  });
}
