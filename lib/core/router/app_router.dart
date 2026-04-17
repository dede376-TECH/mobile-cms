import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/app_core_ui/presentation/screens/home_screen.dart';
import '../../features/player/presentation/screens/players_screen.dart';
import '../../features/schedule/presentation/screens/schedules_screen.dart';
import '../../features/media/presentation/screens/media_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/players',
      builder: (context, state) => const PlayersScreen(),
    ),
    GoRoute(
      path: '/schedules',
      builder: (context, state) => const SchedulesScreen(),
    ),
    GoRoute(path: '/media', builder: (context, state) => const MediaScreen()),
    // Exemple d'ajout de route pour une feature
    /*
    GoRoute(
      path: '/details/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return DetailsScreen(id: id);
      },
    ),
    */
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('Route non trouvée : ${state.error}'))),
);
