import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_routes.dart';
import '../../features/auth/presentation/auth_status_provider.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/notifications/presentation/notification_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/project/presentation/project_selector_screen.dart';
import '../../features/task_board/presentation/kanban_board_screen.dart';
import '../../features/team/presentation/team_management_screen.dart';
import '../../features/timeline/presentation/timeline_screen.dart';
import '../../features/work_organization/presentation/work_organization_screen.dart';

const _splashPath = '/splash';

const screenPaths = <AppScreen, String>{
  AppScreen.login: '/login',
  AppScreen.forgotPassword: '/forgot-password',
  AppScreen.projectSelector: '/projects/select',
  AppScreen.dashboard: '/dashboard',
  AppScreen.workOrganization: '/projects',
  AppScreen.kanbanBoard: '/board',
  AppScreen.teamManagement: '/team',
  AppScreen.timeline: '/timeline',
  AppScreen.profile: '/profile',
  AppScreen.notifications: '/notifications',
};

const _publicPaths = {'/login', '/forgot-password'};

final routerProvider = Provider<GoRouter>((ref) {
  // GoRouter chỉ cần biết "có thay đổi" để chạy lại redirect.
  final refresh = ValueNotifier<AuthStatus>(ref.read(authStatusProvider));
  ref.listen<AuthStatus>(authStatusProvider, (_, next) => refresh.value = next);
  ref.onDispose(refresh.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    final status = ref.read(authStatusProvider);
    final loc = state.matchedLocation;

    if (status == AuthStatus.unknown) {
      return loc == _splashPath ? null : _splashPath;
    }
    if (status == AuthStatus.unauthenticated) {
      return _publicPaths.contains(loc) ? null : screenPaths[AppScreen.login];
    }
    // authenticated: thoát splash / màn đăng nhập → luôn về trang chủ đầu tiên
    if (loc == _splashPath || _publicPaths.contains(loc)) {
      return screenPaths[AppScreen.dashboard];
    }
    return null;
  }

  GoRoute route(AppScreen screen, Widget Function(NavigateTo go) build) {
    return GoRoute(
      path: screenPaths[screen]!,
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: build((target) => context.go(screenPaths[target]!)),
      ),
    );
  }

  return GoRouter(
    initialLocation: _splashPath,
    refreshListenable: refresh,
    redirect: redirect,
    routes: [
      GoRoute(
        path: _splashPath,
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      route(AppScreen.login, (go) => LoginScreen(onNavigate: go)),
      route(AppScreen.forgotPassword, (go) => ForgotPasswordScreen(onNavigate: go)),
      route(AppScreen.projectSelector, (go) => ProjectSelectorScreen(onNavigate: go)),
      route(AppScreen.dashboard, (go) => DashboardScreen(onNavigate: go)),
      route(AppScreen.workOrganization, (go) => WorkOrganizationScreen(onNavigate: go)),
      route(AppScreen.kanbanBoard, (go) => KanbanBoardScreen(onNavigate: go)),
      route(AppScreen.teamManagement, (go) => TeamManagementScreen(onNavigate: go)),
      route(AppScreen.timeline, (go) => TimelineScreen(onNavigate: go)),
      route(AppScreen.profile, (go) => ProfileScreen(onNavigate: go)),
      route(AppScreen.notifications, (go) => NotificationScreen(onNavigate: go)),
    ],
  );
});
