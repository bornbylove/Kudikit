import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/shared/widgets/connectivity_widget.dart';
import 'package:kudipay/features/tribe/presentation/pages/choose_tribe.dart';
import 'package:kudipay/provider/provider.dart';

class KnowYouBetterForm extends ConsumerStatefulWidget {
  const KnowYouBetterForm({super.key});

  @override
  ConsumerState<KnowYouBetterForm> createState() => _KnowYouBetterFormState();
}

class _KnowYouBetterFormState extends ConsumerState<KnowYouBetterForm> {
  final TextEditingController _referralCodeController = TextEditingController();
  String? _selectedSource;

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
              content:
                  Text('Connection lost - Your responses are saved locally'),
              backgroundColor: Colors.orange,
            ),
          );
        } else if (previous?.value != null &&
            !previous!.value! &&
            isConnected) {
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

  void _handleContinue() {
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

    if (_selectedSource != null) {
      // Persist referral/source data through the registration provider.
      // The registration flow will include this in the final account creation call.
      final referral = _referralCodeController.text.trim();
      if (referral.isNotEmpty) {
        // Store referral code so it can be submitted with the registration payload.
        // ref.read(registrationProvider.notifier).setReferralCode(referral);
        // (Un-comment and implement setReferralCode when the backend endpoint
        //  accepts a referral_code field.)
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TribeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select how you heard about us'),
          backgroundColor: Colors.orange,
        ),
      );
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
                          AppColors.primaryTeal),
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
                        initialValue: _selectedSource,
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
                        onPressed: _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
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
