import 'package:go_router/go_router.dart';

final goRouter = GoRouter(
  initialLocation: '/calendar',
  routes: [
    GoRoute(
      path: '/persona-ci',
      // name: PersonaCi.name,
      // builder: (context, state) => const PersonaCi(),
    ),
  ],
);
