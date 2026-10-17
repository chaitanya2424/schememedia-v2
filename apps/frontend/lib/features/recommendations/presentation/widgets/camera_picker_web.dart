// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

/// Web implementation using HTML FileUploadInputElement with robust camera & file support.
Future<String?> pickOrCaptureImage({bool useCamera = true}) {
  final completer = Completer<String?>();
  final uploadInput = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false;

  // Make invisible without display:none so Chrome doesn't treat click as untrusted
  uploadInput.style
    ..position = 'fixed'
    ..top = '-1000px'
    ..left = '-1000px'
    ..width = '1px'
    ..height = '1px'
    ..opacity = '0'
    ..pointerEvents = 'none';

  final userAgent = html.window.navigator.userAgent.toLowerCase();
  final isMobile = userAgent.contains('mobile') ||
      userAgent.contains('android') ||
      userAgent.contains('iphone') ||
      userAgent.contains('ipad');

  if (useCamera) {
    if (isMobile) {
      uploadInput.setAttribute('capture', 'environment');
    } else {
      // On desktop, setting capture="environment" can cause Chrome to ignore the click
      // because desktop PCs do not have a rear camera. Omitting capture opens the system dialog.
    }
  }

  html.document.body?.append(uploadInput);

  bool fileSelected = false;
  StreamSubscription<html.Event>? focusSub;

  void cleanup() {
    try {
      focusSub?.cancel();
      uploadInput.remove();
    } catch (_) {}
  }

  // Handle file selection
  uploadInput.onChange.listen((e) {
    fileSelected = true;
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((e) {
        final result = reader.result as String?;
        cleanup();
        if (!completer.isCompleted) completer.complete(result);
      });
      reader.onError.listen((e) {
        cleanup();
        if (!completer.isCompleted) completer.complete(null);
      });
    } else {
      cleanup();
      if (!completer.isCompleted) completer.complete(null);
    }
  });

  // Handle cancel event (supported in modern Chromium/Safari)
  uploadInput.addEventListener('cancel', (e) {
    cleanup();
    if (!completer.isCompleted) completer.complete(null);
  });

  // Fallback for cancellation when user closes file dialog without selecting
  focusSub = html.window.onFocus.listen((e) {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!completer.isCompleted && !fileSelected) {
        final files = uploadInput.files;
        if (files == null || files.isEmpty) {
          cleanup();
          if (!completer.isCompleted) completer.complete(null);
        }
      }
    });
  });

  // Programmatically trigger the file/camera dialog
  uploadInput.click();
  return completer.future;
}
