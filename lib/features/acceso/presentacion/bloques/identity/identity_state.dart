import 'dart:io';
import 'package:equatable/equatable.dart';

enum IdentityStatus { initial, loading, success, error }

class IdentityState extends Equatable {
  final IdentityStatus status;
  final File? frontImage;
  final File? backImage;
  final File? pdfFile;
  final bool isPdfMode;
  final String scanningMessage;
  final Map<String, dynamic>? extractedData;
  final String? errorMessage;

  const IdentityState({
    this.status = IdentityStatus.initial,
    this.frontImage,
    this.backImage,
    this.pdfFile,
    this.isPdfMode = false,
    this.scanningMessage = '',
    this.extractedData,
    this.errorMessage,
  });

  IdentityState copyWith({
    IdentityStatus? status,
    File? frontImage,
    File? backImage,
    File? pdfFile,
    bool? isPdfMode,
    String? scanningMessage,
    Map<String, dynamic>? extractedData,
    String? errorMessage,
  }) {
    return IdentityState(
      status: status ?? this.status,
      frontImage: frontImage ?? this.frontImage,
      backImage: backImage ?? this.backImage,
      pdfFile: pdfFile ?? this.pdfFile,
      isPdfMode: isPdfMode ?? this.isPdfMode,
      scanningMessage: scanningMessage ?? this.scanningMessage,
      extractedData: extractedData ?? this.extractedData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        frontImage,
        backImage,
        pdfFile,
        isPdfMode,
        scanningMessage,
        extractedData,
        errorMessage,
      ];
}

