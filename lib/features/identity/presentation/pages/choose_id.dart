import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/constants/id_type.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/features/identity/domain/entities/id_verification_state.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/features/identity/presentation/pages/confirm_info.dart';
import 'package:kudipay/features/identity/presentation/controllers/id_verification_controller.dart';
import 'package:kudipay/features/identity/presentation/pages/verification_status.dart';

class IdVerificationScreen extends ConsumerStatefulWidget {
  const IdVerificationScreen({super.key});

  @override
  ConsumerState<IdVerificationScreen> createState() =>
      _IdVerificationScreenState();
}

class _IdVerificationScreenState extends ConsumerState<IdVerificationScreen> {
  final TextEditingController _idNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  IdType _selectedIdType = IdType.bvn;

  final int _progressPercentage = 48;

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(idVerificationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      bottomNavigationBar: _buildNextButton(context, verificationState),
      body: Stack(
        children: [
          _buildBody(context, verificationState),
          if (verificationState.status == VerificationStatus.loading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF069494)),
              ),
            ),
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
      actions: [
        Padding(
          padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
          child: Center(
            child: SizedBox(
              width: AppLayout.scaleWidth(context, 56),
              height: AppLayout.scaleWidth(context, 56),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: AppLayout.scaleWidth(context, 30),
                    height: AppLayout.scaleWidth(context, 30),
                    child: CircularProgressIndicator(
                      value: _progressPercentage / 100,
                      strokeWidth: 3,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF069494),
                      ),
                    ),
                  ),
                  Text(
                    '$_progressPercentage%',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 12),
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
      BuildContext context, IdVerificationState verificationState) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: AppLayout.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            Text(
              'Choose an ID type',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 28),
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 8)),

            Text(
              'We\'ll need a valid ID type to confirm who you are.',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 15),
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),

            _buildIdTypeToggle(context),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),

            _buildIdNumberField(context),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // ? Success state: show verified name card
            if (verificationState.status == VerificationStatus.success &&
                verificationState.data != null)
              _buildFetchedNameDisplay(context, verificationState.data!),

            // ? Error state: show error banner
            if (verificationState.status == VerificationStatus.error &&
                verificationState.error != null)
              Padding(
                padding:
                    EdgeInsets.only(top: AppLayout.scaleHeight(context, 16)),
                child: Container(
                  padding: EdgeInsets.all(AppLayout.scaleWidth(context, 12)),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(
                      AppLayout.scaleWidth(context, 8),
                    ),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: AppLayout.scaleWidth(context, 20),
                      ),
                      SizedBox(width: AppLayout.scaleWidth(context, 12)),
                      Expanded(
                        child: Text(
                          verificationState.error!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: AppLayout.fontSize(context, 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Space so content isn't hidden behind the bottom button
            SizedBox(height: AppLayout.scaleHeight(context, 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildIdTypeToggle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildToggleButton(
            context: context,
            // ? FIX 3: .label from the real IdType extension — no crash
            label: IdType.bvn.label,
            isSelected: _selectedIdType == IdType.bvn,
            onTap: () => setState(() {
              _selectedIdType = IdType.bvn;
              _idNumberController.clear();
              ref.read(idVerificationProvider.notifier).reset();
            }),
          ),
        ),
        SizedBox(width: AppLayout.scaleWidth(context, 12)),
        Expanded(
          child: _buildToggleButton(
            context: context,
            label: IdType.nin.label,
            isSelected: _selectedIdType == IdType.nin,
            onTap: () => setState(() {
              _selectedIdType = IdType.nin;
              _idNumberController.clear();
              ref.read(idVerificationProvider.notifier).reset();
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      child: Container(
        height: AppLayout.scaleHeight(context, 56),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4F1D4) : Colors.white,
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
          border: Border.all(
            color: isSelected ? const Color(0xFF069494) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF069494) : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdNumberField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          // ? .label — from the real IdType extension
          'Your ${_selectedIdType.label}',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 8)),
        TextFormField(
          controller: _idNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          onChanged: (value) {
            if (value.length == 11) _handleVerification();
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your ${_selectedIdType.label}';
            }
            if (value.length != 11) {
              return '${_selectedIdType.label} must be 11 digits';
            }
            return null;
          },
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
          decoration: InputDecoration(
            // ? .hint — uses the hint getter from IdTypeX extension
            hintText: _selectedIdType.hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: AppLayout.fontSize(context, 16),
              letterSpacing: 0,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: const BorderSide(color: Color(0xFF069494), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 16),
              vertical: AppLayout.scaleHeight(context, 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFetchedNameDisplay(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: const Color(0xFF069494),
                size: AppLayout.scaleWidth(context, 20),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 8)),
              Text(
                'Identity Verified',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF171515),
                ),
              ),
            ],
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 12)),
          Text(
            (data['name'] as String? ?? '').toUpperCase(),
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF171515),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(
      BuildContext context, IdVerificationState verificationState) {
    final isEnabled = verificationState.status == VerificationStatus.success &&
        verificationState.data != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppLayout.scaleWidth(context, 20),
        AppLayout.scaleHeight(context, 12),
        AppLayout.scaleWidth(context, 20),
        AppLayout.scaleHeight(context, 28),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9F5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: isEnabled ? _handleNext : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF069494),
            disabledBackgroundColor: Colors.grey[300],
            minimumSize: Size(
              double.infinity,
              AppLayout.scaleHeight(context, 52),
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 28)),
            ),
            elevation: 0,
          ),
          child: Text(
            'Next',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerification() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(idVerificationProvider.notifier)
        .verifyId(_idNumberController.text);
  }

  void _handleNext() {
    final state = ref.read(idVerificationProvider);
    if (state.status != VerificationStatus.success || state.data == null) {
      return;
    }

    // Build a UserInfo from the data returned by the ID verification step.
    // The mock (and real) API returns first_name, last_name, date_of_birth,
    // and the raw BVN/NIN number that the user entered.
    final data = state.data!;
    final userInfo = UserInfo(
      firstName: (data['first_name'] as String? ?? '').trim(),
      lastName: (data['last_name'] as String? ?? '').trim(),
      bvn: _idNumberController.text.trim(),
      dateOfBirth: DateTime.tryParse(
            data['date_of_birth'] as String? ?? '',
          ) ??
          DateTime(1990, 1, 1),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmInfoScreen(userInfo: userInfo),
      ),
    );
  }
}
