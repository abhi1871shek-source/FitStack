import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase/supabase.dart';

void main() async {
  const url = 'https://lbqtvmvfcxdkpfumyrlr.supabase.co';
  const anonKey = 'sb_publishable_XkuJYi-VpEKg6pUADuomPA_NboVFYM2';

  final client = SupabaseClient(url, anonKey);

  try {
    final authResp = await client.auth.signInWithPassword(
      email: 'test_exercise_user@example.com',
      password: 'Password123!',
    );
    final user = authResp.user;
    print('Logged in user ID: ${user?.id}');

    if (user != null) {
      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0xFF, 0xD9]);
      final base64Url = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final itemId = 'ex_custom_${DateTime.now().millisecondsSinceEpoch}';

      final map = {
        'id': itemId,
        'user_id': user.id,
        'name': 'Test Pushup Custom',
        'muscle_group': 'Chest',
        'default_sets': 3,
        'default_reps': 10,
        'default_weight_kg': 0.0,
        'avoid_if': [],
        'image_url': base64Url,
        'is_home': true,
      };

      print('Upserting custom exercise into exercises table...');
      await client.from('exercises').upsert(map, onConflict: 'id');
      print('Exercise row saved!');

      final rows = await client.from('exercises').select().eq('id', itemId);
      print('Queried exercises table row:');
      print('  id: ${rows.first['id']}');
      print('  image_url: ${rows.first['image_url']?.substring(0, 30)}...');

      // Also test inserting into workout_logs
      final logMap = {
        'user_id': user.id,
        'exercise_id': itemId,
        'name': 'Test Pushup Custom',
        'muscle_group': 'Chest',
        'sets': 3,
        'reps': 10,
        'weight_kg': 0.0,
        'set_details': [],
        'is_completed': false,
        'image_url': base64Url,
        'workout_date': DateTime.now().toIso8601String().split('T').first,
      };

      print('Inserting into workout_logs table...');
      final logRes = await client.from('workout_logs').insert(logMap).select();
      print('Queried workout_logs table row image_url: ${logRes.first['image_url']?.substring(0, 30)}...');
    }
  } catch (e, st) {
    print('Error: $e\n$st');
  }
}
