class SelfieState {
  final bool isLoading;
  final String? imagePath;
  final String? error;
  final bool isCameraInitialized;
  final bool faceDetected;
  final bool validationPassed;

  SelfieState({
    this.isLoading = false,
    this.imagePath,
    this.error,
    this.isCameraInitialized = false,
    this.faceDetected = false,
    this.validationPassed = false,
  });

  SelfieState copyWith({
    bool? isLoading,
    String? imagePath,
    String? error,
    bool? isCameraInitialized,
    bool? faceDetected,
    bool? validationPassed,
  }) {
    return SelfieState(
      isLoading: isLoading ?? this.isLoading,
      imagePath: imagePath ?? this.imagePath,
      error: error,
      isCameraInitialized: isCameraInitialized ?? this.isCameraInitialized,
      faceDetected: faceDetected ?? this.faceDetected,
      validationPassed: validationPassed ?? this.validationPassed,
    );
  }
}
