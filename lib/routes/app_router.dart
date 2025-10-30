import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/welcome_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: "/",
      builder: (BuildContext context, GoRouterState state) {
        return const WelcomeScreen();
      },
    ),
  ],
);
