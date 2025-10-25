import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/routing/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'features/auth/auth_provider.dart';
import 'core/providers/car_makes_provider.dart';
import 'core/providers/car_parts_provider.dart';
import 'core/providers/tools_provider.dart';
import 'core/services/hive_storage_service.dart';
import 'core/services/cart_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables with error handling
  try {
    await dotenv.load(fileName: ".env");
    print("✅ Environment variables loaded successfully");
  } catch (e) {
    print("⚠️ Warning: Could not load .env file: $e");
    print("🔧 Using fallback configuration...");
  }

  // Get environment variables from .env file only
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

  print("🌐 Supabase URL: ${supabaseUrl ?? 'Not set'}");
  print(
    "🔑 Supabase Key: ${supabaseKey != null ? '${supabaseKey.substring(0, 20)}...' : 'Not set'}",
  );

  // Validate required environment variables
  if (supabaseUrl == null ||
      supabaseKey == null ||
      supabaseUrl.isEmpty ||
      supabaseKey.isEmpty) {
    throw Exception(
      'Missing required environment variables. Please check your .env file.',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  await EasyLocalization.ensureInitialized();
  await HiveStorageService.init();
  await CartService.init();
  await CarPartsProvider.initializeCache();

  // Clean up expired cache entries on app start
  await CarPartsProvider.cleanupCache();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'), // English
        Locale('ar'), // Arabic
        Locale('he'), // Hebrew
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CarMakesProvider()),
        ChangeNotifierProvider(create: (_) => CarPartsProvider()),
        ChangeNotifierProvider(create: (_) => ToolsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Car Parts Shop',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            builder: (context, child) {
              final isRtl =
                  context.locale.languageCode == 'ar' ||
                  context.locale.languageCode == 'he';
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: 1.0,
                  platformBrightness: themeProvider.isDarkMode
                      ? Brightness.dark
                      : Brightness.light,
                ),
                child: Container(
                  alignment: isRtl
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: DefaultTextStyle(
                    style: DefaultTextStyle.of(context).style,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    child: child!,
                  ),
                ),
              );
            },
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
