import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/network/supabase_client.dart';
import 'core/services/gemini_vision_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await SupabaseService.initialize();
  GeminiVisionService.initialize();

  runApp(
    const ProviderScope(
      child: MataresitApp(),
    ),
  );
}
