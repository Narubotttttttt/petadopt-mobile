import 'package:flutter/material.dart';
import 'package:mobile_petadopt/screens/adoption/adoption_form_screen.dart';
import 'package:mobile_petadopt/screens/auth/login_screen.dart';
import 'package:mobile_petadopt/screens/auth/register_screen.dart';
import 'package:mobile_petadopt/screens/home/home_screen.dart';
import 'package:mobile_petadopt/screens/pets/pet_detail_screen.dart';
import 'package:mobile_petadopt/screens/profile/edit_address_screen.dart';
import 'package:mobile_petadopt/screens/profile/profile_screen.dart';
import 'package:mobile_petadopt/screens/recommendation/match_quiz_screen.dart';
import 'package:mobile_petadopt/screens/splash/splash_screen.dart';
import 'package:mobile_petadopt/services/notification_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize(navigatorKey: navigatorKey);
  await NotificationService.setupFirebaseFCM(navigatorKey: navigatorKey);
  runApp(const PetAdoptApp());
}

class PetAdoptApp extends StatelessWidget {
  const PetAdoptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'CAWS PetAdopt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit-address': (context) => const EditAddressScreen(),
        '/match-quiz': (context) => const MatchQuizScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/pet-detail') {
          final pet = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PetDetailScreen(pet: pet),
          );
        }
        if (settings.name == '/adoption-form') {
          final pet = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => AdoptionFormScreen(pet: pet),
          );
        }
        return null;
      },
    );
  }
}
