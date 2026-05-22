import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class IdentityEvent extends Equatable {
  const IdentityEvent();

  @override
  List<Object?> get props => [];
}

class IdentityFrontImageChanged extends IdentityEvent {
  final File file;
  const IdentityFrontImageChanged(this.file);
  @override
  List<Object?> get props => [file];
}

class IdentityBackImageChanged extends IdentityEvent {
  final File file;
  const IdentityBackImageChanged(this.file);
  @override
  List<Object?> get props => [file];
}

class IdentityPdfFileChanged extends IdentityEvent {
  final File file;
  const IdentityPdfFileChanged(this.file);
  @override
  List<Object?> get props => [file];
}

class IdentityProcessStarted extends IdentityEvent {
  final bool isPdfMode;
  const IdentityProcessStarted({this.isPdfMode = false});
  @override
  List<Object?> get props => [isPdfMode];
}

class IdentityScanningStatusUpdated extends IdentityEvent {
  final String message;
  const IdentityScanningStatusUpdated(this.message);
  @override
  List<Object?> get props => [message];
}

class IdentityReset extends IdentityEvent {
  const IdentityReset();
}

class IdentityCaptureStarted extends IdentityEvent {
  final bool isFront;
  const IdentityCaptureStarted(this.isFront);
  @override
  List<Object?> get props => [isFront];
}

class IdentityCaptureFailed extends IdentityEvent {
  const IdentityCaptureFailed();
}

/// Solicitud explícita para cancelar el procesamiento OCR actual.
/// Se usa cuando el usuario navega a otro paso para evitar que el OCR siga "corriendo" en segundo plano.
class IdentityProcessCancelRequested extends IdentityEvent {
  const IdentityProcessCancelRequested();
}

