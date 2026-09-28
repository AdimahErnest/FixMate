// FixMate — entry point: Supabase init, providers, and MaterialApp

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_state.dart';
import 'theme.dart';
import 'widgets/connectivity.dart';
import 'pages/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: 'https://bxfekcnibpzybsuqtvfw.supabase.co',
      publishableKey: 'sb_publishable_iD82G2crN4l-_AwwFhEV2g_JlTt71W0',
    );
    debugPrint('✅ Supabase connected successfully!');
  } catch (e) {
    debugPrint('❌ Connection failed: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const FixMateApp(),
    ),
  );
}

class FixMateApp extends StatefulWidget {
  const FixMateApp({super.key});

  @override
  State<FixMateApp> createState() => _FixMateAppState();
}

class _FixMateAppState extends State<FixMateApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadSettings();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return MaterialApp(
          title: 'FixMate',
          debugShowCheckedModeBanner: false,
          themeMode: state.themeMode,
          theme: FixMateTheme.lightTheme,
          darkTheme: FixMateTheme.darkTheme,
          home: const SplashScreen(),
          builder: (context, child) => ConnectivityWrapper(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
