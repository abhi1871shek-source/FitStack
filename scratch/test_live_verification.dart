import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('=== CREATING USER-UPLOADS BUCKET & VERIFYING PHOTO UPLOAD ===');

  const url = 'https://lbqtvmvfcxdkpfumyrlr.supabase.co';
  const anonKey = 'sb_publishable_XkuJYi-VpEKg6pUADuomPA_NboVFYM2';

  const testEmail = 'photo_test_user@fitstack.com';
  const testPassword = 'Password123!';

  final loginRes = await http.post(
    Uri.parse('$url/auth/v1/token?grant_type=password'),
    headers: {
      'apikey': anonKey,
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': testEmail,
      'password': testPassword,
    }),
  );

  final body = jsonDecode(loginRes.body);
  final accessToken = body['access_token'];
  final userId = body['user']['id'];
  print('Logged in user: $userId');

  // Try creating bucket 'user-uploads' via Storage REST API
  final createBucketRes = await http.post(
    Uri.parse('$url/storage/v1/bucket'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'id': 'user-uploads',
      'name': 'user-uploads',
      'public': true,
    }),
  );
  print('Create Bucket Response (${createBucketRes.statusCode}): ${createBucketRes.body}');

  // Now upload image test
  final bytes = await File('test_salad.png').readAsBytes();
  final foodCustomId = 'f_custom_${DateTime.now().millisecondsSinceEpoch}';
  final foodStoragePath = '$userId/foods/$foodCustomId.jpg';

  final uploadRes = await http.post(
    Uri.parse('$url/storage/v1/object/user-uploads/$foodStoragePath'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'image/jpeg',
      'x-upsert': 'true',
    },
    body: bytes,
  );
  print('Upload Response (${uploadRes.statusCode}): ${uploadRes.body}');

  final foodPublicUrl = '$url/storage/v1/object/public/user-uploads/$foodStoragePath';
  print('Public URL: $foodPublicUrl');

  final getRes = await http.get(Uri.parse(foodPublicUrl));
  print('Direct HTTP GET Status: ${getRes.statusCode}');
}
