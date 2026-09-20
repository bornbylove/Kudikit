import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/constant/id_type.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/IDdocument/id_verification_state.dart';
import 'package:kudipay/model/tier/tier_model.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/presentation/Identity/confirm_info.dart';
import 'package:kudipay/presentation/Identity/id_verification_controller.dart';
import 'package:kudipay/presentation/Identity/verification_status.dart';
import 'package:kudipay/presentation/kyc/kyc_next_step.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/tier/tier_provider.dart';

class IdVerificationScreen extends ConsumerStatefulWidget {
  const IdVerificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<IdVerificationScreen> createState() =>
      _IdVerificationScreenState();
}

class _IdVerificationScreenState extends ConsumerState<IdVerificationScreen> {
  final TextEditingController _idNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();


  IdType _selectedIdType = IdType.bvn;

  final int _progressPercentage = 48;

  // Accumulates identity data across BOTH verification calls when the tier
  // requires BVN AND NIN (Pro/Mega) — each success merges in, rather than
  // ConfirmInfoScreen only ever seeing whichever identifier was checked last.
  UserInfo? _accumulatedInfo;

  @override
  void initState() {
    super.initState();
    // Resuming user who already verified one of BVN/NIN in a prior session
    // (KycFlowManager routed them back here because the other is still
    // missing) — default straight to the one still needed instead of
    // re-prompting for the one already done.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      IdType? resumeType;
      if (user.isBvnVerified && !user.isNinVerified) {
        resumeType = IdType.nin;
      } else if (user.isNinVerified && !user.isBvnVerified) {
        resumeType = IdType.bvn;
      }
      if (resumeType != null && resumeType != _selectedIdType) {
        setState(() => _selectedIdType = resumeType!);
        ref.read(idVerificationProvider.notifier).changeIdType(resumeType);
      }
    });
  }

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

            // ✅ Success state: show verified name card
            if (verificationState.status == VerificationStatus.success &&
                verificationState.data != null)
              _buildFetchedNameDisplay(context, verificationState.data!),

            // ✅ Error state: show error banner
            if (verificationState.status == VerificationStatus.error &&
                verificationState.error != null)
              Padding(
                padding: EdgeInsets.only(
                    top: AppLayout.scaleHeight(context, 16)),
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
            // ✅ FIX 3: .label from the real IdType extension — no crash
            label: IdType.bvn.label,
            isSelected: _selectedIdType == IdType.bvn,
            onTap: () => setState(() {
              _selectedIdType = IdType.bvn;
              _idNumberController.clear();
              // Slice 5 FIX: actually propagate the type to the controller —
              // the old `reset()` kept state.idType at BVN forever, so NIN was
              // always verified as BVN.
              ref
                  .read(idVerificationProvider.notifier)
                  .changeIdType(IdType.bvn);
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
              ref
                  .read(idVerificationProvider.notifier)
                  .changeIdType(IdType.nin);
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
              color:
                  isSelected ? const Color(0xFF069494) : Colors.grey[700],
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
          // ✅ .label — from the real IdType extension
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
            // ✅ .hint — uses the hint getter from IdTypeX extension
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
              borderSide:
                  const BorderSide(color: Color(0xFF069494), width: 2),
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
        borderRadius:
            BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
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
            color: Colors.black.withOpacity(0.05),
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
    if (state.status != VerificationStatus.success || state.data == null) return;

    // Slice 5: the real verify-* response exposes the registry identity via
    // `fullName` / `dateOfBirth` (the old mock's first_name/last_name/
    // date_of_birth shape does NOT exist on the auth-service). The entered
    // number goes to bvn or nin depending on which type was verified.
    final data = state.data!;
    final name = (data['fullName'] as String? ?? '').trim();
    final nameParts = name.split(' ').where((p) => p.isNotEmpty).toList();
    final isBvn = state.idType == IdType.bvn;
    final enteredNumber = _idNumberController.text.trim();

    // Merge into whatever we've accumulated so far this session — Pro/Mega
    // verify BVN and NIN as two separate calls, not one. (A prior-session
    // identifier isn't recoverable here since only the "verified" flag
    // persists, not the raw digits — ConfirmInfoScreen shows that field
    // blank in that specific resume case; the gating below is what matters.)
    _accumulatedInfo = UserInfo(
      firstName: nameParts.isNotEmpty
          ? nameParts.first
          : (_accumulatedInfo?.firstName ?? ''),
      lastName: nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : (_accumulatedInfo?.lastName ?? ''),
      bvn: isBvn ? enteredNumber : (_accumulatedInfo?.bvn ?? ''),
      nin: isBvn ? (_accumulatedInfo?.nin ?? '') : enteredNumber,
      dateOfBirth: DateTime.tryParse(data['dateOfBirth'] as String? ?? '') ??
          _accumulatedInfo?.dateOfBirth ??
          DateTime(1990, 1, 1),
    );

    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final tier = effectiveKycTier(user, ref.read(tierProvider).currentTier);

    // FIX: this used to advance to ConfirmInfoScreen after ANY single BVN-or-
    // NIN success, even for Pro/Mega, which require BOTH. Basic is genuinely
    // OR — one success is enough.
    final needsBoth = tier != TierLevel.basic;
    if (needsBoth && !(user.isBvnVerified && user.isNinVerified)) {
      final justVerified = isBvn ? 'BVN' : 'NIN';
      final nextType = user.isBvnVerified ? IdType.nin : IdType.bvn;
      setState(() {
        _selectedIdType = nextType;
        _idNumberController.clear();
      });
      ref.read(idVerificationProvider.notifier).changeIdType(nextType);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '$justVerified verified! Now enter your ${nextType.label} to continue.'),
          backgroundColor: const Color(0xFF069494),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Both required identifiers are verified (or Basic's OR is satisfied) —
    // go to whatever this tier still needs next (ID doc / address for
    // Pro/Mega), not straight to ConfirmInfoScreen every time.
    final nextScreen = nextIncompleteKycStep(tier, user);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            nextScreen ?? ConfirmInfoScreen(userInfo: _accumulatedInfo!),
      ),
    );
  }
}