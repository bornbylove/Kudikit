class TransactionFormatter {
  /// Format amount with thousand separators
  static String formatAmount(double amount) {
    String amountStr = amount.abs().toStringAsFixed(2);
    List<String> parts = amountStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];

    // Add thousand separators
    String formatted = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formatted += ',';
      }
      formatted += integerPart[i];
    }

    return '$formatted.$decimalPart';
  }

  /// Format date and time for transaction
  static String formatDateTime(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    String day = date.day.toString().padLeft(2, '0');
    String month = months[date.month - 1];
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    String second = date.second.toString().padLeft(2, '0');

    return '$month $day, $hour:$minute:$second';
  }

  /// Format date header
  static String formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (transactionDate == yesterday) {
      return 'Yesterday';
    }

    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    String dayName = days[date.weekday - 1];
    String monthName = months[date.month - 1];
    String dayWithSuffix = _getDayWithSuffix(date.day);

    return '$dayName, $monthName $dayWithSuffix, ${date.year}';
  }

  static String _getDayWithSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }
}
