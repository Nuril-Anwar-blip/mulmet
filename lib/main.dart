import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'services/bank_service.dart';
import 'services/settings_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('id_ID');
  await SettingsService.load();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  final hasSession = await BankService.restoreSession();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(BankMandiriApp(hasSession: hasSession));
}

class BankMandiriApp extends StatefulWidget {
  final bool hasSession;

  const BankMandiriApp({super.key, required this.hasSession});

  static final settingsNotifier = ValueNotifier<int>(0);

  static void refreshSettings() {
    settingsNotifier.value++;
  }

  @override
  State<BankMandiriApp> createState() => _BankMandiriAppState();
}

class _BankMandiriAppState extends State<BankMandiriApp> {
  @override
  void initState() {
    super.initState();
    BankMandiriApp.settingsNotifier.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    BankMandiriApp.settingsNotifier.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.current;
    return MaterialApp(
      title: 'Bank Mandiri',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode:
          settings.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      home: widget.hasSession ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
