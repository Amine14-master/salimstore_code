import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Conditional import - uses web_init.dart on web, web_stub.dart on other platforms
import 'utils/web_stub.dart' if (dart.library.html) 'utils/web_init.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth_screen.dart';
import 'screens/home_page.dart';
import 'screens/splash_screen.dart';
import 'services/locale_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize WebView platform (only on web, no-op on mobile)
  initializeWebView();

  // Ensure Firebase is initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final localeController = LocaleController();
  await localeController.loadSavedLocale();
  runApp(
    LocaleScope(
      controller: localeController,
      child: LivriyesApp(localeController: localeController),
    ),
  );
}

class LivriyesApp extends StatelessWidget {
  const LivriyesApp({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) {
        return MaterialApp(
          locale: localeController.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          onGenerateTitle: (context) => context.l10n.appTitle,
          theme: AppTheme.theme,
          debugShowCheckedModeBanner: false,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show the Flutter splash screen (identical to native) to ensure continuity
          return const SplashScreen();
        }

        // Remove native splash when we have data (either user or null)
        FlutterNativeSplash.remove();

        if (snapshot.hasData) {
          // User is signed in, show client home page
          return const LivriyesHomePage();
        } else {
          // User is not signed in, show auth screen
          return const ClientAuthScreen();
        }
      },
    );
  }
}
