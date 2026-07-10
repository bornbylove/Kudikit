import 'dart:io';

enum DocumentType {
  utilityBill('Utility Bill'),
  nationalId('National ID'),
  passport('Passport'),
  driversLicense('Driver\'s License'),
  votersCard('Voter\'s Card');

  final String displayName;
  const DocumentType(this.displayName);
}

class DocumentUploadData {
  final DocumentType? documentType;
  final File? uploadedFile;
  final String? fileName;
  final double uploadProgress;

  DocumentUploadData({
    this.documentType,
    this.uploadedFile,
    this.fileName,
    this.uploadProgress = 0.0,
  });

  DocumentUploadData copyWith({
    DocumentType? documentType,
    File? uploadedFile,
    String? fileName,
    double? uploadProgress,
  }) {
    return DocumentUploadData(
      documentType: documentType ?? this.documentType,
      uploadedFile: uploadedFile ?? this.uploadedFile,
      fileName: fileName ?? this.fileName,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  bool get isComplete => documentType != null && uploadedFile != null;
}
