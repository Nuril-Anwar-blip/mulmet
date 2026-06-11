import 'package:flutter_dotenv/flutter_dotenv.dart';

const _fallbackSupabaseUrl = 'https://movicgnvjitgbubospwo.supabase.co';
const _fallbackSupabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vdmljZ252aml0Z2J1Ym9zcHdvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA1ODkzMzQsImV4cCI6MjA5NjE2NTMzNH0.VX6jQVlGJqxIrOrnIx5inbDJIwf1S8DfX6nG_847kLc';

String _configValue({
  required String dartDefineName,
  required String envName,
  required String fallback,
}) {
  const dartDefineValues = {
    'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
    'SUPABASE_PUBLISHABLE_KEY':
        String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY'),
  };

  final dartDefineValue = dartDefineValues[dartDefineName];
  if (dartDefineValue != null && dartDefineValue.isNotEmpty) {
    return dartDefineValue;
  }

  final envValue = dotenv.env[envName]?.trim();
  if (envValue != null && envValue.isNotEmpty) {
    return envValue;
  }

  return fallback;
}

String get supabaseUrl => _configValue(
      dartDefineName: 'SUPABASE_URL',
      envName: 'SUPABASE_URL',
      fallback: _fallbackSupabaseUrl,
    );

String get supabasePublishableKey {
  final publishableKey = _configValue(
    dartDefineName: 'SUPABASE_PUBLISHABLE_KEY',
    envName: 'SUPABASE_PUBLISHABLE_KEY',
    fallback: '',
  );
  if (publishableKey.isNotEmpty) return publishableKey;

  return _configValue(
    dartDefineName: 'SUPABASE_ANON_KEY',
    envName: 'SUPABASE_ANON_KEY',
    fallback: _fallbackSupabaseKey,
  );
}
