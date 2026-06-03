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
import 'package:form_field_validator/form_field_validator.dart';
import 'package:kudipay/core/theme/app_theme.dart';

// =============================================================================
// Spacing & Duration
// =============================================================================

const double kDefaultPadding   = 16.0;
const double kSmallPadding     = 8.0;
const double kLargePadding     = 24.0;
const double kBorderRadius     = 12.0;

const Duration kDefaultDuration = Duration(milliseconds: 250);
const Duration kLongDuration    = Duration(milliseconds: 500);

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

// =============================================================================
// Form Validators
// =============================================================================

final passwordValidator = MultiValidator([
  RequiredValidator(errorText: 'Password is required'),
  MinLengthValidator(8, errorText: 'Password must be at least 8 digits long'),
  PatternValidator(
    r'(?=.*?[#?!@$%^&*-/])',
    errorText: 'Password must have at least one special character',
  ),
]);

final emailValidator = MultiValidator([
  RequiredValidator(errorText: 'Email is required'),
  EmailValidator(errorText: 'Enter a valid email address'),
]);

final requiredValidator = RequiredValidator(errorText: 'This field is required');
final matchValidator    = MatchValidator(errorText: 'Passwords do not match');

final phoneNumberValidator = MinLengthValidator(
  10,
  errorText: 'Phone number must be at least 10 digits long',
);

// =============================================================================
// IdType
// =============================================================================

enum IdType { bvn, nin }

extension IdTypeX on IdType {
  String get label {
    switch (this) {
      case IdType.bvn: return 'BVN';
      case IdType.nin: return 'NIN';
    }
  }

  String get hint {
    switch (this) {
      case IdType.bvn: return 'Enter your 11-digit BVN';
      case IdType.nin: return 'Enter your 11-digit NIN';
    }
  }
}