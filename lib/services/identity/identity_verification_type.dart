// lib/services/identity/identity_verification_type.dart
//
// Extension point for the identity-verification services living in this
// directory. Only `liveness` is implemented today (LivenessVerificationService,
// backed by Dojah's Liveness Check API) — `bvn` and `nin` are named here so
// future BvnVerificationService/NinVerificationService siblings have an
// obvious, consistent place to register, without forcing a shared interface
// into existence before there's a second implementation to justify one.

enum IdentityVerificationType { liveness, bvn, nin }
