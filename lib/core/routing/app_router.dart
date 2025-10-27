import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/welcome/welcome_screen.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/password_reset_page.dart';
import '../../features/auth/pages/role_selection_page.dart';
import '../../features/auth/pages/buyer_signup_page.dart';
import '../../features/auth/pages/garage_owner_signup_page.dart';
import '../../features/user/pages/user_dashboard.dart';
import '../../features/user/pages/settings/profile_page.dart';
import '../../features/user/pages/settings/about_page.dart';
import '../../features/user/pages/settings/help_page.dart';
import '../../features/user/pages/car_details/car_details_page.dart';
import '../../features/products/presentation/pages/category_selection_page.dart';
import '../../features/user/pages/car_parts/part_details_page.dart';
import '../api/models/car_part.dart';

class AppRouter {
  static const String welcome = '/';
  static const String login = '/login';
  static const String passwordReset = '/password-reset';
  static const String signup = '/signup';
  static const String buyerSignup = '/signup/buyer';
  static const String garageOwnerSignup = '/signup/garage';
  static const String dashboard = '/dashboard';
  static const String home = '/home';
  static const String tools = '/tools';
  static const String cart = '/cart';
  static const String sales = '/sales';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String about = '/about';
  static const String help = '/help';
  static const String carDetails = '/car-details/:carMake';
  static const String carParts = '/car-parts/:carId';
  static const String partDetails = '/part-details';

  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: welcome,
        builder: (BuildContext context, GoRouterState state) {
          return const WelcomeScreen();
        },
      ),
      GoRoute(
        path: login,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginPage();
        },
      ),
      GoRoute(
        path: passwordReset,
        builder: (BuildContext context, GoRouterState state) {
          return const PasswordResetPage();
        },
      ),
      GoRoute(
        path: signup,
        builder: (BuildContext context, GoRouterState state) {
          return const RoleSelectionPage();
        },
      ),
      GoRoute(
        path: buyerSignup,
        builder: (BuildContext context, GoRouterState state) {
          return const BuyerSignupPage();
        },
      ),
      GoRoute(
        path: garageOwnerSignup,
        builder: (BuildContext context, GoRouterState state) {
          return const GarageOwnerSignupPage();
        },
      ),
      GoRoute(
        path: dashboard,
        builder: (BuildContext context, GoRouterState state) {
          final initialTabIndexStr =
              state.uri.queryParameters['initialTabIndex'];
          final initialTabIndex = initialTabIndexStr != null
              ? int.tryParse(initialTabIndexStr) ?? 0
              : 0;
          return UserDashboard(initialTabIndex: initialTabIndex);
        },
      ),
      GoRoute(
        path: home,
        builder: (BuildContext context, GoRouterState state) {
          return UserDashboard(initialTabIndex: 0);
        },
      ),
      GoRoute(
        path: tools,
        builder: (BuildContext context, GoRouterState state) {
          return UserDashboard(initialTabIndex: 1);
        },
      ),
      GoRoute(
        path: cart,
        builder: (BuildContext context, GoRouterState state) {
          return UserDashboard(initialTabIndex: 3); // Fixed: Cart is index 3
        },
      ),
      GoRoute(
        path: sales,
        builder: (BuildContext context, GoRouterState state) {
          return UserDashboard(initialTabIndex: 2); // Fixed: Sales is index 2
        },
      ),
      GoRoute(
        path: settings,
        builder: (BuildContext context, GoRouterState state) {
          return UserDashboard(initialTabIndex: 4);
        },
      ),
      GoRoute(
        path: profile,
        builder: (BuildContext context, GoRouterState state) {
          return const ProfilePage();
        },
      ),
      GoRoute(
        path: about,
        builder: (BuildContext context, GoRouterState state) {
          return const AboutPage();
        },
      ),
      GoRoute(
        path: help,
        builder: (BuildContext context, GoRouterState state) {
          return const HelpPage();
        },
      ),
      GoRoute(
        path: carDetails,
        builder: (BuildContext context, GoRouterState state) {
          final carMake = state.pathParameters['carMake'] ?? '';
          final logoUrl = state.uri.queryParameters['logoUrl'] ?? '';
          return CarDetailsPage(carMake: carMake, logoUrl: logoUrl);
        },
      ),
      GoRoute(
        path: carParts,
        builder: (BuildContext context, GoRouterState state) {
          final carIdStr = state.pathParameters['carId'] ?? '0';
          final carId = int.tryParse(carIdStr) ?? 0;
          final carName = state.uri.queryParameters['carName'] ?? '';
          return CategorySelectionPage(carId: carId, carName: carName);
        },
      ),
      GoRoute(
        path: partDetails,
        builder: (BuildContext context, GoRouterState state) {
          // We expect the CarPart instance to be passed via state.extra
          final extra = state.extra;
          if (extra is CarPart) {
            return PartDetailsPage(part: extra);
          }

          // Fallback UI when the part was not passed correctly
          return Scaffold(
            appBar: AppBar(title: const Text('Part Details')),
            body: const Center(child: Text('Part not found')),
          );
        },
      ),
    ],
  );
}
