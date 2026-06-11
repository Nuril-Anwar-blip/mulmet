import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePhotoService {
  ProfilePhotoService._();

  static const _keyPrefix = 'profile_photo';

  static String _key(String userId) => '$_keyPrefix:$userId';

  static Future<String?> pickAndSave(String userId) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image == null) return null;

    final bytes = await image.readAsBytes();
    final encoded = base64Encode(bytes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), encoded);
    return encoded;
  }

  static Future<String?> getPhoto(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(userId));
  }

  static Future<void> clearPhoto(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }
}
