import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/constants/colors.dart';
import 'providers/user_provider.dart';
import 'providers/drawing_provider.dart';
import 'routes/app_router.dart';
import 'services/actions/base_api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');

  await EasyLocalization.ensureInitialized();

  // Create user provider and check auth status
  final userProvider = UserProvider();
  await userProvider.checkAuthStatus();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => DrawingProvider()),
      ],
      child: EasyLocalization(
        supportedLocales: [Locale('en'), Locale('de')],
        path: 'assets/translations',
        fallbackLocale: Locale('en'),
        startLocale: Locale('en'),
        child: MainApp(),
      ),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Create router once and reuse it
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _router = createAppRouter(userProvider);

    // Register 401 Unauthorized callback to logout user
    BaseApiService.setOnUnauthorizedCallback(() {
      print('🔐 Handling 401 - Logging out user');
      userProvider.logout();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NovaDraw AI',

      debugShowCheckedModeBanner: false,

      // Add EasyLocalization configuration
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      theme: ThemeData(
        primarySwatch: MaterialColor(0xFF4DA6FF, {
          50: AppColors.primaryLight,
          100: AppColors.primaryLight,
          200: AppColors.primaryLight,
          300: AppColors.primary,
          400: AppColors.primary,
          500: AppColors.primary,
          600: AppColors.primaryDark,
          700: AppColors.primaryDark,
          800: AppColors.primaryDark,
          900: AppColors.primaryDark,
        }),
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.background,
        ),
      ),

      routerConfig: _router,
    );
  }
}
