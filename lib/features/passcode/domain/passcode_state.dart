class PasscodeState {
  final String enteredPasscode;
  final String? originalPasscode;
  final bool showError;
  final bool isConfirmed;
  final bool isLoading;

  PasscodeState({
    this.enteredPasscode = '',
    this.originalPasscode,
    this.showError = false,
    this.isConfirmed = false,
    this.isLoading = false,
  });

  PasscodeState copyWith({
    String? enteredPasscode,
    String? originalPasscode,
    bool? showError,
    bool? isConfirmed,
    bool? isLoading,
  }) {
    return PasscodeState(
      enteredPasscode: enteredPasscode ?? this.enteredPasscode,
      originalPasscode: originalPasscode ?? this.originalPasscode,
      showError: showError ?? this.showError,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
