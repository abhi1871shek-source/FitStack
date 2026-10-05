import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const url = 'https://lbqtvmvfcxdkpfumyrlr.supabase.co';
  const anonKey = 'sb_publishable_XkuJYi-VpEKg6pUADuomPA_NboVFYM2';

  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
  };

  print('=== ALL FOOD ITEMS ===');
  final foodsRes = await http.get(Uri.parse('$url/rest/v1/food_items?select=id,name,image_asset,user_id&order=created_at.desc&limit=10'), headers: headers);
  print(foodsRes.body);

  print('=== ALL EXERCISES ===');
  final exercisesRes = await http.get(Uri.parse('$url/rest/v1/exercises?select=id,name,image_url,user_id,default_weight_kg&order=created_at.desc&limit=10'), headers: headers);
  print(exercisesRes.body);

  print('=== ALL FOOD LOGS ===');
  final foodLogsRes = await http.get(Uri.parse('$url/rest/v1/food_logs?select=id,name,image_asset,user_id&order=created_at.desc&limit=10'), headers: headers);
  print(foodLogsRes.body);

  print('=== ALL WORKOUT LOGS ===');
  final workoutLogsRes = await http.get(Uri.parse('$url/rest/v1/workout_logs?select=id,name,image_url,weight_kg,user_id&order=created_at.desc&limit=10'), headers: headers);
  print(workoutLogsRes.body);
}
