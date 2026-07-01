import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// 裁切一個已選的圖片路徑；使用者取消時回傳原路徑。
Future<XFile?> cropImagePath(String path) async {
  final cropped = await ImageCropper().cropImage(
    sourcePath: path,
    uiSettings: [
      IOSUiSettings(
        title: '裁切圖片',
        aspectRatioLockEnabled: false,
        resetAspectRatioEnabled: true,
      ),
      AndroidUiSettings(
        toolbarTitle: '裁切圖片',
        lockAspectRatio: false,
        toolbarColor: const Color(0xFFE8A52A),
        toolbarWidgetColor: Colors.white,
      ),
    ],
  );
  return XFile(cropped?.path ?? path);
}

/// 從相簿挑一張圖並裁切；沒選則回 null。
Future<XFile?> pickAndCropImage({int imageQuality = 90}) async {
  final picked = await ImagePicker()
      .pickImage(source: ImageSource.gallery, imageQuality: imageQuality);
  if (picked == null) return null;
  return cropImagePath(picked.path);
}
