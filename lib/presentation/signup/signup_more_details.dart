import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/connectivity_widget.dart';
import 'package:kudipay/presentation/tribe/choose_tribe.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/config/dio_client.dart';


class KnowYouBetterForm extends ConsumerStatefulWidget {
  const KnowYouBetterForm({Key? key}) : super(key: key);

  @override
  ConsumerState<KnowYouBetterForm> createState() => _KnowYouBetterFormState();
}

class _KnowYouBetterFormState extends ConsumerState<KnowYouBetterForm> {
  final TextEditingController _referralCodeController = TextEditingController();
  String? _selectedSource;
  bool _isSubmitting = false;

  final List<String> _hearAboutOptions = [
    'Social Media',
    'Friend/Family',
    'Online Advertisement',
    'Search Engine',
    'App Store',
    'News/Blog',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupConnectivityListener();
    });
  }

  void _setupConnectivityListener() {
    ref.listen(connectivityProvider, (previous, next) {
      next.whenData((isConnected) {
        if (previous?.value != null && previous!.value! && !isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection lost - Your responses are saved locally'),
              backgroundColor: Colors.orange,
            ),
          );
        } else if (previous?.value != null && !previous!.value! && isConnected) {
          ConnectivitySnackBar.showConnectionRestored(context);
        }
      });
    });
  }

  @override
  void dispose() {
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final isConnected = ref.read(currentConnectivityProvider);

    if (!isConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.wifi_off, size: 48, color: Colors.orange),
          title: const Text('No Internet Connection'),
          content: const Text(
            'You need internet to continue to the next step. Your responses are saved and will be submitted when you reconnect.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(connectivityStateProvider.notifier).refresh();
              },
              child: const Text('Check Connection'),
            ),
          ],
        ),
      );
      return;
    }

    if (_selectedSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select how you heard about us'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // This is where /auth/register actually fires — after OTP verification
    // (screen 2) and referral collection (this screen), matching the
    // backend's referral-at-registration design.
    final flow = ref.read(registrationFlowProvider);
    if (!flow.hasBasicInfo || flow.otpReference == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your session expired — please restart sign up.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final referral = _referralCodeController.text.trim();

    setState(() => _isSubmitting = true);
    try {
      final response = await ref.read(authServiceProvider).register(
            otpReference: flow.otpReference!,
            phoneNumber: flow.phoneNumber!,
            email: flow.email!,
            // fullName intentionally not collected — see the backend
            // advisory on RegisterRequest.fullName still being @NotBlank
            // server-side; this call will 400 until that ships.
            passcode: flow.passcode!,
            confirmPasscode: flow.passcode!,
            referralCode: referral.isNotEmpty ? referral : null,
          );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception(response['message'] ?? 'Registration failed. Please try again.');
      }
      await ref.read(authProvider.notifier).completeSession(data);
      await ref
          .read(storageServiceProvider)
          .savePasscode(flow.passcode!, phoneNumber: flow.phoneNumber);
      ref.read(registrationFlowProvider.notifier).clear();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TribeScreen()),
      );
    } on KudiNetworkException {
      if (mounted) ConnectivitySnackBar.showNoInternet(context);
    } on KudiApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivityState = ref.watch(connectivityStateProvider);
    final isOnline = connectivityState.isConnected;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: AppLayout.scaleWidth(context, 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Connectivity indicator
          if (!isOnline)
            Padding(
              padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 8)),
              child: const Center(child: ConnectivityIndicator()),
            ),
          Padding(
            padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
            child: Center(
              child: Stack(
                children: [
                  SizedBox(
                    width: AppLayout.scaleWidth(context, 30),
                    height: AppLayout.scaleWidth(context, 30),
                    child: CircularProgressIndicator(
                      value: 0.75,
                      strokeWidth: AppLayout.scaleWidth(context, 2),
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF069494)),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '75%',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 12),
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Connectivity Banner
          if (!isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You can't fill this form offline. Internet needed to continue.",
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Help us know you better',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'Fill in the required details',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // How did you hear about Kudikit?
                    const Text(
                      'How did you hear about Kudikit?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedSource,
                        decoration: const InputDecoration(
                          hintText: 'Select',
                          hintStyle: TextStyle(
                            color: Colors.black26,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black54,
                        ),
                        dropdownColor: Colors.white,
                        items: _hearAboutOptions.map((String option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(
                              option,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSource = newValue;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Referral Code
                    const Text(
                      'Referral Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Referral Code Input
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _referralCodeController,
                        decoration: const InputDecoration(
                          hintText: 'Enter referral code (optional)',
                          hintStyle: TextStyle(
                            color: Colors.black26,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_isSubmitting || !isOnline) ? null : _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF069494),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isOnline
                                        ? 'Choose Your Tribe'
                                        : 'No Internet Connection',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (!isOnline)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.wifi_off,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}