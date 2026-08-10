// lib/core/constants/app_constants.dart
//
// Single barrel for all app-wide constants and validators.
// Colors and text styles live in app_theme.dart — not here.
//
// Contents:
//   • Spacing / duration constants
//   • Input decorations
//   • Form validators
//   • IdType enum + extension
//
// Usage:
//   import 'package:kudipay/core/constants/app_constants.dart';

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:kudipay/core/theme/app_theme.dart';

// =============================================================================
// Spacing & Duration
// =============================================================================

const double kDefaultPadding = 16.0;
const double kSmallPadding = 8.0;
const double kLargePadding = 24.0;
const double kBorderRadius = 12.0;

const Duration kDefaultDuration = Duration(milliseconds: 250);
const Duration kLongDuration = Duration(milliseconds: 500);

// =============================================================================
// Common EdgeInsets
// =============================================================================

const EdgeInsets kScreenPadding = EdgeInsets.symmetric(
  horizontal: kDefaultPadding,
  vertical: kDefaultPadding,
);

const EdgeInsets kTextFieldPadding = EdgeInsets.symmetric(
  horizontal: kDefaultPadding,
  vertical: kDefaultPadding,
);

// =============================================================================
// Input Decorations
// =============================================================================

const OutlineInputBorder kDefaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(6)),
  borderSide: BorderSide(color: AppColors.inputBorder),
);

const OutlineInputBorder kErrorInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(6)),
  borderSide: BorderSide(color: AppColors.error, width: 1),
);

const InputDecoration kOtpInputDecoration = InputDecoration(
  contentPadding: EdgeInsets.zero,
  counterText: '',
  errorStyle: TextStyle(height: 0),
);

// IdType and IdTypeX live in features/kyc/domain/entities/kyc_entities.dart.
// A byte-identical copy used to sit here; importing both files made `IdType`
// ambiguous, which is how an earlier duplicate let a screen bind to the wrong
// provider. Do not reintroduce it.
