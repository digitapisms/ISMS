import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/school_branding.dart';
import '../../../core/tenant/tenant_context.dart';
import '../../admin/presentation/super_admin_dashboard.dart';
import '../../authentication/application/auth_providers.dart';
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
import '../../../core/localization/widgets/language_selector.dart';

class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  int _selectedIndex = 0;

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
      // Handle error silently
    }
  }

  Future<void> _handleSignOut() async {
    await ref.read(authStateProvider.notifier).signOut();
    ref.read(tenantContextProvider.notifier).clear();
    ref.read(schoolBrandingProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final authUser = ref.watch(authStateProvider);

    // Load school context on mount
    if (authUser != null && authUser.schoolId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSchoolContext(ref, authUser.schoolId!);
      });
    }

    final branding = ref.watch(schoolBrandingProvider);

    // Super Admin Dashboard
    if (authUser?.role == UserRole.superAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('ILMA Cloud Portal - Super Admin')),
        body: const SuperAdminDashboard(),
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
              branding.schoolName ?? 'ILMA Cloud Portal',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
        actions: [
          if (authUser != null) ...[
            const LanguageSelector(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  authUser.email,
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
                  const NavigationRailDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart),
                    label: Text('Reports'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.payment_outlined),
                    selectedIcon: Icon(Icons.payment),
                    label: Text('Payments'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    selectedIcon: Icon(Icons.account_balance_wallet),
                    label: Text('Fee Management'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.assignment_outlined),
                    selectedIcon: Icon(Icons.assignment),
                    label: Text('Examinations'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.schedule_outlined),
                    selectedIcon: Icon(Icons.schedule),
                    label: Text('Timetable'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.assignment_outlined),
                    selectedIcon: Icon(Icons.assignment),
                    label: Text('Assignments'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.library_books_outlined),
                    selectedIcon: Icon(Icons.library_books),
                    label: Text('Library'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.directions_bus_outlined),
                    selectedIcon: Icon(Icons.directions_bus),
                    label: Text('Transport'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.quiz_outlined),
                    selectedIcon: Icon(Icons.quiz),
                    label: Text('Enrichment'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.auto_awesome_outlined),
                    selectedIcon: Icon(Icons.auto_awesome),
                    label: Text('AI Tutor'),
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
                  const NavigationRailDestination(
                    icon: Icon(Icons.backup_outlined),
                    selectedIcon: Icon(Icons.backup),
                    label: Text('Backup'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.insights_outlined),
                    selectedIcon: Icon(Icons.insights),
                    label: Text('Advanced Reports'),
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
        return const ReportsAnalyticsScreen();
      case 5:
        return const PaymentManagementScreen();
      case 6:
        return const FeeManagementScreen();
      case 7:
        return const ExaminationScreen();
      case 8:
        return const TimetableScreen();
      case 9:
        return const AssignmentsScreen();
      case 10:
        return const LibraryScreen();
      case 11:
        return const TransportScreen();
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
        return const BackupRestoreScreen();
      case 26:
        return const AdvancedReportsScreen();
      case 27:
        return const PerformanceDashboardScreen();
      default:
        return const StudentListScreen();
    }
  }
}
