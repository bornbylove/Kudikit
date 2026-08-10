// lib/features/passcode/domain/passcode_state.dart

/// Which half of the create-then-confirm flow the user is in.
enum PasscodeStage { create, confirm }

class PasscodeState {
  /// Digits entered so far in the current stage.
  final String enteredPasscode;

  /// The passcode captured in the [PasscodeStage.create] stage, held while the
  /// user re-enters it. Null until the first stage completes.
  final String? originalPasscode;

  final PasscodeStage stage;
  final bool showError;
  final String? errorMessage;

  /// True once both entries match — the passcode is ready to be consumed.
  final bool isConfirmed;
  final bool isLoading;

  const PasscodeState({
    this.enteredPasscode = '',
    this.originalPasscode,
    this.stage = PasscodeStage.create,
    this.showError = false,
    this.errorMessage,
    this.isConfirmed = false,
    this.isLoading = false,
  });

  PasscodeState copyWith({
    String? enteredPasscode,
    String? originalPasscode,
    PasscodeStage? stage,
    bool? showError,
    String? errorMessage,
    bool? isConfirmed,
    bool? isLoading,
    bool clearOriginal = false,
  }) {
    return PasscodeState(
      enteredPasscode: enteredPasscode ?? this.enteredPasscode,
      originalPasscode:
          clearOriginal ? null : (originalPasscode ?? this.originalPasscode),
      stage: stage ?? this.stage,
      showError: showError ?? this.showError,
      errorMessage: errorMessage,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
