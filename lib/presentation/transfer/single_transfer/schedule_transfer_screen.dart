import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/features/transfer/presentation/controllers/transfer_controller.dart';
import 'package:kudipay/provider/provider.dart';

class ScheduledTransferScreen extends ConsumerStatefulWidget {
  const ScheduledTransferScreen({super.key});

  @override
  ConsumerState<ScheduledTransferScreen> createState() =>
      _ScheduledTransferScreenState();
}

class _ScheduledTransferScreenState
    extends ConsumerState<ScheduledTransferScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedRepeat = 'Once';
  bool _sendReminder = true;

  final List<String> _repeatOptions = [
    'Once',
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF069494),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF069494),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(p2pTransferProvider);
    final recipient = state.transferData.recipient;
    final amount = state.transferData.amount;
    final currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _buildBody(context, recipient, amount, currencyFormat),
          _buildScheduleButton(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F9F5),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Scheduled Transfers',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(
    BuildContext context,
    RecipientInfo? recipient,
    double? amount,
    NumberFormat currencyFormat,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Transfer details card
            Container(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    'Amount',
                    currencyFormat.format(amount ?? 0),
                  ),
                  Divider(color: Colors.grey[200], height: 24),
                  _buildDetailRow(
                    context,
                    'Name',
                    recipient?.name ?? '',
                  ),
                  Divider(color: Colors.grey[200], height: 24),
                  _buildDetailRow(
                    context,
                    'Account number',
                    recipient?.accountNumber ?? '',
                  ),
                ],
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Schedule settings card
            Container(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Text(
                    'Date',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 8)),
                  TextField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: _selectDate,
                    decoration: InputDecoration(
                      hintText: 'dd/mm/yy',
                      hintStyle: TextStyle(
                        color: Colors.black26,
                        fontSize: AppLayout.fontSize(context, 14),
                      ),
                      suffixIcon: const Icon(Icons.calendar_today, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF069494),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 20)),

                  // Time
                  Text(
                    'Time',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 8)),
                  TextField(
                    controller: _timeController,
                    readOnly: true,
                    onTap: _selectTime,
                    decoration: InputDecoration(
                      hintText: '00:00',
                      hintStyle: TextStyle(
                        color: Colors.black26,
                        fontSize: AppLayout.fontSize(context, 14),
                      ),
                      suffixIcon: const Icon(Icons.access_time, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF069494),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Repeat dropdown
            Container(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Repeat',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 8)),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRepeat,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF069494),
                          width: 2,
                        ),
                      ),
                    ),
                    items: _repeatOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRepeat = value!;
                      });
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Send reminder toggle
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 20),
                vertical: AppLayout.scaleHeight(context, 12),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Send reminder 1hr before payment?',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      color: Colors.black87,
                    ),
                  ),
                  Switch(
                    value: _sendReminder,
                    onChanged: (value) {
                      setState(() {
                        _sendReminder = value;
                      });
                    },
                    activeThumbColor: const Color(0xFF069494),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 13),
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleButton(BuildContext context) {
    final canSchedule = _selectedDate != null && _selectedTime != null;

    return Positioned(
      bottom: AppLayout.scaleHeight(context, 24),
      left: AppLayout.scaleWidth(context, 24),
      right: AppLayout.scaleWidth(context, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: AppLayout.scaleHeight(context, 52),
            child: ElevatedButton(
              onPressed: canSchedule
                  ? () {
                      final state = ref.read(p2pTransferProvider);
                      final recipient = state.transferData.recipient;
                      final amount = state.transferData.amount;
                      final fmt =
                          NumberFormat.currency(symbol: '₦', decimalDigits: 2);
                      final scheduledDt = DateTime(
                        _selectedDate!.year,
                        _selectedDate!.month,
                        _selectedDate!.day,
                        _selectedTime!.hour,
                        _selectedTime!.minute,
                      );
                      final label =
                          DateFormat('MMM d, yyyy h:mm a').format(scheduledDt);
                      // Persist schedule via provider when API is ready.
                      // For now confirm in-UI and pop.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${fmt.format(amount ?? 0)} to '
                            '${recipient?.name ?? 'recipient'} '
                            'scheduled for $label',
                          ),
                          backgroundColor: const Color(0xFF069494),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canSchedule
                    ? const Color(0xFF069494)
                    : const Color(0xFFB2DFDB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Text(
                'Schedule Payment',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 8)),
          Text(
            'Payment would be made at the time set.',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 12),
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
