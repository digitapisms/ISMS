import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/accessibility/accessibility_provider.dart';
import '../../../core/accessibility/accessibility_utils.dart';

import '../../../core/branding/school_branding.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/subscription/feature_badged_navigation_destination.dart';
import '../../../core/subscription/feature_guard.dart';
import '../../../core/tenant/tenant_context.dart';
import '../../../core/tenant/school_context_provider.dart';
import '../../../core/tenant/school_context_initializer.dart';
import '../../admin/presentation/super_admin_dashboard.dart';
import '../../authentication/application/auth_providers.dart';
import '../../authentication/domain/app_user.dart';
import '../../authentication/domain/user_role.dart';
import '../../school_registration/application/school_providers.dart';
import '../../class_management/presentation/class_management_screen.dart';
import '../../notifications/presentation/notification_management_screen.dart';
import '../../reports/presentation/reports_analytics_screen.dart';
import '../../staff_management/presentation/staff_management_screen.dart';
import '../../school_settings/presentation/school_settings_screen.dart';
import '../../student_management/presentation/student_list_screen.dart';
import '../../student_management/presentation/application_status_screen.dart';
import '../../student_management/presentation/admin_application_review_screen.dart';
import '../../payments/presentation/payment_management_screen.dart';
import '../../enrichment/presentation/enrichment_screen.dart';
import '../../ai/presentation/ai_chat_screen.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../fee_management/presentation/fee_management_screen.dart';
import '../../examination/presentation/examination_screen.dart';
import '../../timetable/presentation/timetable_screen.dart';
import '../../assignments/presentation/assignments_screen.dart';
import '../../library/presentation/library_screen.dart';
import '../../transport/presentation/transport_screen.dart';
import '../../messaging/presentation/messaging_screen.dart';
import '../../certificates/presentation/certificates_screen.dart';
import '../../visitor_management/presentation/visitor_management_screen.dart';
import '../../events/presentation/events_screen.dart';
import '../../parent_portal/presentation/parent_portal_screen.dart';
import '../../discipline/presentation/discipline_screen.dart';
import '../../documents/presentation/documents_screen.dart';
import '../../ptm/presentation/ptm_screen.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../backup_restore/presentation/backup_restore_screen.dart';
import '../../reports/presentation/advanced_reports_screen.dart';
import '../../performance/presentation/performance_dashboard_screen.dart';
import '../../../core/theme/presentation/theme_settings_screen.dart';

class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  int _selectedIndex = 0;
  bool _hasLoadedSchool = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadSchoolContext(WidgetRef ref, String schoolId) async {
    try {
      final schoolRepo = ref.read(schoolRepositoryProvider);
      final school = await schoolRepo.getSchoolById(schoolId);
      if (school != null) {
        ref.read(tenantContextProvider.notifier).setSchool(school);

        // Update branding
        ref
            .read(schoolBrandingProvider.notifier)
            .updateBranding(
              SchoolBranding(
                schoolName: school.name,
                logoUrl: school.logoUrl,
                primaryColor: school.primaryColor != null
                    ? Color(
                        int.parse(
                          school.primaryColor!.replaceFirst('#', '0xFF'),
                        ),
                      )
                    : null,
                secondaryColor: school.secondaryColor != null
                    ? Color(
                        int.parse(
                          school.secondaryColor!.replaceFirst('#', '0xFF'),
                        ),
                      )
                    : null,
              ),
            );
      }
    } catch (e) {
      debugPrint('Error loading school context: $e');
    }
  }

  Future<void> _tryLoadSchoolByUser(WidgetRef ref, AppUser user) async {
    try {
      // Try to find school where user is admin/principal
      final client = SupabaseManager.client;
      final userRows = await client
          .from('users')
          .select('id, school_id')
          .eq('auth_id', user.id)
          .limit(1);

      if (userRows.isNotEmpty) {
        final row = (userRows as List).first as Map<String, dynamic>;
        final schoolId = row['school_id'] as String?;

        if (schoolId != null) {
          await _loadSchoolContext(ref, schoolId);
          return;
        }
      }

      // If still no school, try to find by user's role and email domain
      // This is a fallback for newly created schools
      if (user.role == UserRole.admin || user.role == UserRole.principal) {
        final schools = await client
            .from('schools')
            .select('id, name')
            .ilike('email', '%${user.email.split('@').last}%')
            .limit(1);

        if (schools.isNotEmpty) {
          final school = (schools as List).first as Map<String, dynamic>;
          final schoolId = school['id'] as String;
          await _loadSchoolContext(ref, schoolId);
        }
      }
    } catch (e) {
      debugPrint('Error trying to load school by user: $e');
    }
  }

  Future<void> _handleSignOut() async {
    await ref.read(authStateProvider.notifier).signOut();
    ref.read(tenantContextProvider.notifier).clear();
    ref.read(schoolBrandingProvider.notifier).clear();
  }

  void _handleKeyboardNavigation(KeyEvent event, bool isAdmin) {
    final accessibilitySettings = ref.read(accessibilitySettingsProvider);

    if (!accessibilitySettings.keyboardNavigation) {
      return;
    }

    if (event is RawKeyDownEvent) {
      final logicalKey = event.logicalKey;

      // Navigation using number keys (1-9 for first 9 items, 0 for 10th)
      if (logicalKey == LogicalKeyboardKey.digit1) {
        _navigateToIndex(0, isAdmin);
      } else if (logicalKey == LogicalKeyboardKey.digit2) {
        _navigateToIndex(1, isAdmin);
      } else if (logicalKey == LogicalKeyboardKey.digit3) {
        _navigateToIndex(2, isAdmin);
      } else if (logicalKey == LogicalKeyboardKey.digit4) {
        _navigateToIndex(3, isAdmin);
      } else if (logicalKey == LogicalKeyboardKey.digit5) {
        _navigateToIndex(4, isAdmin);
      } else if (logicalKey == LogicalKeyboardKey.digit6) {
        _navigateToIndex(5, isAdmin);
      } else if (logicalKey == LogicalKeyboardKey.digit7) {
        _navigateToIndex(6, isAdmin);
      } else if (logicalKey == LogicalKeyboardKey.digit8) {
        _navigateToIndex(7, isAdmin);
      } else if (logicalKey == LogicalKeyboardKey.digit9) {
        _navigateToIndex(8, isAdmin);
      } else if (logicalKey == LogicalKeyboardKey.digit0) {
        _navigateToIndex(9, isAdmin);
      }
      // Arrow key navigation
      else if (logicalKey == LogicalKeyboardKey.arrowRight) {
        _navigateToIndex(
          (_selectedIndex + 1) % _getMaxNavigationIndex(isAdmin),
          isAdmin,
        );
      } else if (logicalKey == LogicalKeyboardKey.arrowLeft) {
        _navigateToIndex(
          (_selectedIndex - 1) % _getMaxNavigationIndex(isAdmin),
          isAdmin,
        );
      }
      // Escape key to focus on navigation
      else if (logicalKey == LogicalKeyboardKey.escape) {
        // Focus management could be added here
      }
    }
  }

  void _navigateToIndex(int index, bool isAdmin) {
    final maxIndex = _getMaxNavigationIndex(isAdmin);
    if (index >= 0 && index < maxIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  int _getMaxNavigationIndex(bool isAdmin) {
    // Return the maximum navigation index based on user role
    return isAdmin ? 28 : 1; // 28 destinations for admin, 1 for others
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final authUser = ref.watch(authStateProvider);

    // Initialize school context - MUST be watched so it stays alive and reacts
    // to auth changes. Using read() here can lead to the initializer being
    // disposed and school context never loading (infinite spinners across tabs).
    ref.watch(schoolContextInitializerProvider);

    // Also watch the loader so the dashboard can gate rendering until the
    // school is available (prevents "infinite loading" in feature tabs).
    final schoolLoader = ref.watch(schoolContextLoaderProvider);
    final currentSchool = ref.watch(currentSchoolProvider);

    // Also load school context on mount (legacy fallback)
    if (authUser != null && !_hasLoadedSchool) {
      setState(() => _hasLoadedSchool = true);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          // Try to load from user's school_id first
          if (authUser.schoolId != null) {
            await _loadSchoolContext(ref, authUser.schoolId!);
          } else {
            // If no school_id in user, try to find school by user's email/role
            await _tryLoadSchoolByUser(ref, authUser);
          }
        }
      });
    } else if (authUser == null && _hasLoadedSchool) {
      // Reset when user logs out
      setState(() => _hasLoadedSchool = false);
    }

    final branding = ref.watch(schoolBrandingProvider);

    // Super Admin Dashboard
    if (authUser?.role == UserRole.superAdmin) {
      return const SuperAdminDashboard();
    }

    // Gate: for logged-in non-superadmin users, ensure school context is loaded
    // before rendering the feature shell. This prevents multiple tabs from
    // seeing a null school and showing endless loading indicators.
    if (authUser != null && currentSchool == null) {
      return schoolLoader.when(
        data: (school) => school == null
            ? const Scaffold(
                body: Center(
                  child: Text(
                    'Unable to determine your school. Please sign out and sign in again.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : const Scaffold(body: Center(child: CircularProgressIndicator())),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => const Scaffold(
          body: Center(
            child: Text(
              'Unable to load school context. Please sign in again.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Show applicant-specific screens
    if (authUser?.role == UserRole.applicant) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              if (branding.logoUrl != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      branding.logoUrl!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              Text(
                branding.schoolName ?? 'Student Application',
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.palette_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ThemeSettingsScreen(),
                  ),
                );
              },
              tooltip: 'Theme Settings',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '${authUser?.email}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleSignOut,
              tooltip: 'Sign out',
            ),
          ],
        ),
        body: const ApplicationStatusScreen(),
      );
    }

    // For admin/principal, show application review option
    final isAdmin =
        authUser?.role == UserRole.admin ||
        authUser?.role == UserRole.principal ||
        authUser?.role == UserRole.superAdmin;

    return FocusableWidget(
      enabled: ref.watch(accessibilitySettingsProvider).keyboardNavigation,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) => _handleKeyboardNavigation(event, isAdmin),
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                if (branding.logoUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        branding.logoUrl!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                Text(
                  branding.schoolName ?? 'ILMA Cloud Portal',
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            actions: [
              if (authUser != null) ...[
                Semantics(
                  label: 'Theme settings button',
                  child: IconButton(
                    icon: const Icon(Icons.palette_outlined),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ThemeSettingsScreen(),
                        ),
                      );
                    },
                    tooltip: 'Theme Settings',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Text(
                      authUser.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                Semantics(
                  label: 'Sign out button',
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: _handleSignOut,
                    tooltip: 'Sign out',
                  ),
                ),
              ],
            ],
          ),
          body: Row(
            children: [
              if (isWide)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.school_outlined),
                      selectedIcon: Icon(Icons.school),
                      label: Text('Students'),
                    ),
                    if (isAdmin) ...[
                      const NavigationRailDestination(
                        icon: Icon(Icons.class_outlined),
                        selectedIcon: Icon(Icons.class_),
                        label: Text('Classes'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.check_circle_outline),
                        selectedIcon: Icon(Icons.check_circle),
                        label: Text('Attendance'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.group_outlined),
                        selectedIcon: Icon(Icons.group),
                        label: Text('Staff'),
                      ),
                      createFeatureBadgedNavigationDestination(
                        icon: const Icon(Icons.bar_chart_outlined),
                        selectedIcon: const Icon(Icons.bar_chart),
                        label: const Text('Reports'),
                        featureKey: 'advanced_reports',
                        ref: ref,
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.payment_outlined),
                        selectedIcon: Icon(Icons.payment),
                        label: Text('Payments'),
                      ),
                      createFeatureBadgedNavigationDestination(
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                        selectedIcon: const Icon(Icons.account_balance_wallet),
                        label: const Text('Fee Management'),
                        featureKey: 'fee_management',
                        ref: ref,
                      ),
                      createFeatureBadgedNavigationDestination(
                        icon: const Icon(Icons.assignment_outlined),
                        selectedIcon: const Icon(Icons.assignment),
                        label: const Text('Examinations'),
                        featureKey: 'exam_management',
                        ref: ref,
                      ),
                      createFeatureBadgedNavigationDestination(
                        icon: const Icon(Icons.schedule_outlined),
                        selectedIcon: const Icon(Icons.schedule),
                        label: const Text('Timetable'),
                        featureKey: 'timetable_management',
                        ref: ref,
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.assignment_outlined),
                        selectedIcon: Icon(Icons.assignment),
                        label: Text('Assignments'),
                      ),
                      createFeatureBadgedNavigationDestination(
                        icon: const Icon(Icons.library_books_outlined),
                        selectedIcon: const Icon(Icons.library_books),
                        label: const Text('Library'),
                        featureKey: 'library_management',
                        ref: ref,
                      ),
                      createFeatureBadgedNavigationDestination(
                        icon: const Icon(Icons.directions_bus_outlined),
                        selectedIcon: const Icon(Icons.directions_bus),
                        label: const Text('Transport'),
                        featureKey: 'transport_management',
                        ref: ref,
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.quiz_outlined),
                        selectedIcon: Icon(Icons.quiz),
                        label: Text('Enrichment'),
                      ),
                      createFeatureBadgedNavigationDestination(
                        icon: const Icon(Icons.auto_awesome_outlined),
                        selectedIcon: const Icon(Icons.auto_awesome),
                        label: const Text('AI Tutor'),
                        featureKey: 'ai_tutor',
                        ref: ref,
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.description_outlined),
                        selectedIcon: Icon(Icons.description),
                        label: Text('Applications'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.chat_outlined),
                        selectedIcon: Icon(Icons.chat),
                        label: Text('Messaging'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.workspace_premium_outlined),
                        selectedIcon: Icon(Icons.workspace_premium),
                        label: Text('Certificates'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.person_search_outlined),
                        selectedIcon: Icon(Icons.person_search),
                        label: Text('Visitors'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.event_outlined),
                        selectedIcon: Icon(Icons.event),
                        label: Text('Events'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.gavel_outlined),
                        selectedIcon: Icon(Icons.gavel),
                        label: Text('Discipline'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.folder_outlined),
                        selectedIcon: Icon(Icons.folder),
                        label: Text('Documents'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.handshake_outlined),
                        selectedIcon: Icon(Icons.handshake),
                        label: Text('PTM'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.inventory_2_outlined),
                        selectedIcon: Icon(Icons.inventory_2),
                        label: Text('Inventory'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.notifications_outlined),
                        selectedIcon: Icon(Icons.notifications),
                        label: Text('Notifications'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings),
                        label: Text('Settings'),
                      ),
                      createFeatureBadgedNavigationDestination(
                        icon: const Icon(Icons.backup_outlined),
                        selectedIcon: const Icon(Icons.backup),
                        label: const Text('Backup'),
                        featureKey: 'backup_restore',
                        ref: ref,
                      ),
                      createFeatureBadgedNavigationDestination(
                        icon: const Icon(Icons.insights_outlined),
                        selectedIcon: const Icon(Icons.insights),
                        label: const Text('Advanced Reports'),
                        featureKey: 'advanced_reports',
                        ref: ref,
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.speed_outlined),
                        selectedIcon: Icon(Icons.speed),
                        label: Text('Performance'),
                      ),
                    ],
                  ],
                ),
              Expanded(child: _getScreenForIndex(_selectedIndex, isAdmin)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getScreenForIndex(int index, bool isAdmin) {
    final currentUser = ref.watch(authStateProvider);
    final isParent = currentUser?.role == UserRole.parent;

    if (isParent) {
      return const ParentPortalScreen();
    }

    if (!isAdmin) {
      return const StudentListScreen();
    }

    switch (index) {
      case 0:
        return const StudentListScreen();
      case 1:
        return const ClassManagementScreen();
      case 2:
        return const AttendanceScreen();
      case 3:
        return const StaffManagementScreen();
      case 4:
        return FeatureGuard(
          featureKey: 'advanced_reports',
          child: const ReportsAnalyticsScreen(),
        );
      case 5:
        return const PaymentManagementScreen();
      case 6:
        return FeatureGuard(
          featureKey: 'fee_management',
          child: const FeeManagementScreen(),
        );
      case 7:
        return FeatureGuard(
          featureKey: 'exam_management',
          child: const ExaminationScreen(),
        );
      case 8:
        return FeatureGuard(
          featureKey: 'timetable_management',
          child: const TimetableScreen(),
        );
      case 9:
        return const AssignmentsScreen();
      case 10:
        return FeatureGuard(
          featureKey: 'library_management',
          child: const LibraryScreen(),
        );
      case 11:
        return FeatureGuard(
          featureKey: 'transport_management',
          child: const TransportScreen(),
        );
      case 12:
        return const EnrichmentScreen();
      case 13:
        return const AiChatScreen();
      case 14:
        return const AdminApplicationReviewScreen();
      case 15:
        return const MessagingScreen();
      case 16:
        return const CertificatesScreen();
      case 17:
        return const VisitorManagementScreen();
      case 18:
        return const EventsScreen();
      case 19:
        return const DisciplineScreen();
      case 20:
        return const DocumentsScreen();
      case 21:
        return const PTMScreen();
      case 22:
        return const InventoryScreen();
      case 23:
        return const NotificationManagementScreen();
      case 24:
        return const SchoolSettingsScreen();
      case 25:
        return FeatureGuard(
          featureKey: 'backup_restore',
          child: const BackupRestoreScreen(),
        );
      case 26:
        return FeatureGuard(
          featureKey: 'advanced_reports',
          child: const AdvancedReportsScreen(),
        );
      case 27:
        return const PerformanceDashboardScreen();
      default:
        return const StudentListScreen();
    }
  }
}
