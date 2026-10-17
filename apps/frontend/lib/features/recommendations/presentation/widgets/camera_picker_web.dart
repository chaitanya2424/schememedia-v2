// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

/// Web implementation using HTML FileUploadInputElement with camera capture support.
Future<String?> pickOrCaptureImage({bool useCamera = true}) {
  final completer = Completer<String?>();
  final uploadInput = html.FileUploadInputElement()..accept = 'image/*';

  if (useCamera) {
    uploadInput.setAttribute('capture', 'environment');
  }

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((e) {
        final result = reader.result as String?;
        completer.complete(result);
      });
      reader.onError.listen((e) {
        completer.complete(null);
      });
    } else {
      completer.complete(null);
    }
  });

  uploadInput.click();
  return completer.future;
}
