import 'camera_picker_stub.dart'
    if (dart.library.html) 'camera_picker_web.dart' as platform_picker;

Future<String?> pickOrCaptureImage({bool useCamera = true}) =>
    platform_picker.pickOrCaptureImage(useCamera: useCamera);
