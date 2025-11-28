import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/login/presentation/pages/pages.dart';

final goRouter = GoRouter(
  initialLocation: '/inicial-page',
  routes: [
    GoRoute(
      path: '/inicial-page',
      name: InicialPage.name,
      builder: (context, state) => const InicialPage(),
    ),
    GoRoute(
      path: '/login',
      name: LoginPage.name,
      builder: (context, state) => const LoginPage(),
    ),
  ],
);
