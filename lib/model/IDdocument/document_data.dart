import 'dart:io';

enum DocumentType {
  utilityBill('Utility Bill'),
  nationalId('National ID'),
  passport('Passport'),
  driversLicense('Driver\'s License'),
  votersCard('Voter\'s Card');

  final String displayName;
  const DocumentType(this.displayName);

  /// Backend wire value for POST /auth/kyc/verify-id-document.
  /// [utilityBill] has NO backend equivalent and must never be submitted as
  /// an ID-document type (the upload screen filters it out of the dropdown).
  String get backendValue {
    switch (this) {
      case DocumentType.nationalId:
        return 'NATIONAL_ID';
      case DocumentType.driversLicense:
        return 'DRIVERS_LICENSE';
      case DocumentType.votersCard:
        return 'VOTERS_CARD';
      case DocumentType.passport:
        return 'PASSPORT';
      case DocumentType.utilityBill:
        return 'UTILITY_BILL';
    }
  }

  /// Two-sided documents require a back image; passport does not.
  bool get backRequired {
    switch (this) {
      case DocumentType.passport:
        return false;
      case DocumentType.driversLicense:
      case DocumentType.nationalId:
      case DocumentType.votersCard:
      case DocumentType.utilityBill:
        return true;
    }
  }
}

class DocumentUploadData {
  final DocumentType? documentType;
  final File? frontImage;
  final String? frontImageName;
  final File? backImage;
  final String? backImageName;
  final double uploadProgress;

  DocumentUploadData({
    this.documentType,
    this.frontImage,
    this.frontImageName,
    this.backImage,
    this.backImageName,
    this.uploadProgress = 0.0,
  });

  DocumentUploadData copyWith({
    DocumentType? documentType,
    File? frontImage,
    String? frontImageName,
    File? backImage,
    String? backImageName,
    double? uploadProgress,
  }) {
    return DocumentUploadData(
      documentType: documentType ?? this.documentType,
      frontImage: frontImage ?? this.frontImage,
      frontImageName: frontImageName ?? this.frontImageName,
      backImage: backImage ?? this.backImage,
      backImageName: backImageName ?? this.backImageName,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  bool get backRequired => documentType?.backRequired ?? false;

  /// Submittable only when the document type is set, the front is picked, and
  /// the back is present for two-sided documents.
  bool get isComplete =>
      documentType != null &&
      frontImage != null &&
      (!backRequired || backImage != null);
}