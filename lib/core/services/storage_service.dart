import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService._();

  static const String bucketName = 'user-uploads';

  /// Ensures bucket is accessible/created if client permissions allow.
  static Future<void> _ensureBucketExists() async {
    try {
      final client = Supabase.instance.client;
      await client.storage.createBucket(
        bucketName,
        const BucketOptions(public: true),
      );
    } catch (_) {
      // Bucket already exists or client lacks admin permission
    }
  }

  /// Uploads raw image bytes to Supabase Storage bucket under `{userId}/{subFolder}/{itemId}.jpg`
  /// Returns the public URL of the uploaded image on success, or base64 data URL fallback.
  static Future<String?> uploadImage({
    required Uint8List imageBytes,
    required String userId,
    required String subFolder, // 'foods' or 'exercises'
    required String itemId,
  }) async {
    try {
      await _ensureBucketExists();

      final client = Supabase.instance.client;
      final path = '$userId/$subFolder/$itemId.jpg';

      debugPrint('[StorageService] Uploading image to bucket "$bucketName" at path: $path');

      await client.storage.from(bucketName).uploadBinary(
        path,
        imageBytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      final publicUrl = client.storage.from(bucketName).getPublicUrl(path);
      debugPrint('[StorageService] Image uploaded successfully. Public URL: $publicUrl');
      return publicUrl;
    } catch (e, st) {
      debugPrint('[StorageService] Note: Storage upload failed ($e). Using self-contained base64 image URL.');
      final base64Str = base64Encode(imageBytes);
      return 'data:image/jpeg;base64,$base64Str';
    }
  }
}
