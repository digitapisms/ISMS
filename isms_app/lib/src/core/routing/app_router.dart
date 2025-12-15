import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/application/auth_providers.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_shell.dart';

final appRouterProvider = Provider<RouterConfig<Object>>((ref) {
  return RouterConfig(
    routerDelegate: _AppRouterDelegate(ref),
    routeInformationProvider: PlatformRouteInformationProvider(
      initialRouteInformation: const RouteInformation(location: '/'),
    ),
    routeInformationParser: _AppRouteInformationParser(),
  );
});

enum AppRoute { login, dashboard }

class _AppRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  _AppRouterDelegate(this.ref);

  final Ref ref;
  AppRoute _currentRoute = AppRoute.login;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Watch auth state and update route accordingly
    final authUser = ref.watch(authStateProvider);
    
    if (authUser != null && _currentRoute == AppRoute.login) {
      _currentRoute = AppRoute.dashboard;
      notifyListeners();
    } else if (authUser == null && _currentRoute == AppRoute.dashboard) {
      _currentRoute = AppRoute.login;
      notifyListeners();
    }

    return Navigator(
      key: navigatorKey,
      pages: [
        if (_currentRoute == AppRoute.login)
          const MaterialPage(child: LoginScreen()),
        if (_currentRoute == AppRoute.dashboard)
          const MaterialPage(child: DashboardShell()),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        if (_currentRoute == AppRoute.dashboard) {
          _currentRoute = AppRoute.login;
          notifyListeners();
        }
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(configuration) async {
    // For now we keep simple routing; can be extended later.
  }
}

class _AppRouteInformationParser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    return Object();
  }
}
