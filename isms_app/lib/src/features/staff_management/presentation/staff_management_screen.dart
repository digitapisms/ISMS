import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../authentication/domain/user_role.dart';
import '../application/staff_providers.dart';
import '../domain/staff_invite.dart';
import '../domain/staff_member.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StaffListFilters _staffFilters = (query: null, role: null, status: 'active');
  StaffInviteFilters _inviteFilters = (status: 'pending');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.group), text: 'Team'),
            Tab(icon: Icon(Icons.mail_outline), text: 'Invites'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Invite Staff',
            onPressed: () => _showInviteDialog(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _StaffListTab(
            filters: _staffFilters,
            onFiltersChanged: (filters) {
              setState(() => _staffFilters = filters);
            },
          ),
          _StaffInvitesTab(
            filters: _inviteFilters,
            onFilterChanged: (filters) {
              setState(() => _inviteFilters = filters);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showInviteDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const _InviteStaffDialog(),
    );

    if (result == true && mounted) {
      ref.invalidate(staffInvitesProvider((status: _inviteFilters.status)));
    }
  }
}

class _StaffListTab extends ConsumerStatefulWidget {
  const _StaffListTab({required this.filters, required this.onFiltersChanged});

  final StaffListFilters filters;
  final ValueChanged<StaffListFilters> onFiltersChanged;

  @override
  ConsumerState<_StaffListTab> createState() => _StaffListTabState();
}

class _StaffListTabState extends ConsumerState<_StaffListTab> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.filters.query ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider(widget.filters));

    return Column(
      children: [
        _StaffFilters(
          searchController: _searchController,
          filters: widget.filters,
          onChanged: widget.onFiltersChanged,
        ),
        Expanded(
          child: staffAsync.when(
            data: (staff) {
              if (staff.isEmpty) {
                return const _EmptyState(
                  icon: Icons.group_off,
                  title: 'No staff members yet',
                  subtitle: 'Invite teachers or staff to get started.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: staff.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final member = staff[index];
                  return _StaffCard(
                    member: member,
                    onChanged: () =>
                        ref.invalidate(staffListProvider(widget.filters)),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorState(
              message: 'Unable to load staff: ',
              onRetry: () => ref.invalidate(staffListProvider(widget.filters)),
            ),
          ),
        ),
      ],
    );
  }
}

class _StaffFilters extends StatelessWidget {
  const _StaffFilters({
    required this.searchController,
    required this.filters,
    required this.onChanged,
  });

  final TextEditingController searchController;
  final StaffListFilters filters;
  final ValueChanged<StaffListFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => onChanged((
                query: value.isEmpty ? null : value,
                role: filters.role,
                status: filters.status,
              )),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: filters.role,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All roles')),
                      DropdownMenuItem(
                        value: 'principal',
                        child: Text('Principal'),
                      ),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(
                        value: 'teacher',
                        child: Text('Teacher'),
                      ),
                      DropdownMenuItem(value: 'staff', child: Text('Staff')),
                    ],
                    onChanged: (value) => onChanged((
                      query: filters.query,
                      role: value,
                      status: filters.status,
                    )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: filters.status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All statuses'),
                      ),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Inactive'),
                      ),
                      DropdownMenuItem(
                        value: 'suspended',
                        child: Text('Suspended'),
                      ),
                    ],
                    onChanged: (value) => onChanged((
                      query: filters.query,
                      role: filters.role,
                      status: value,
                    )),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffCard extends ConsumerWidget {
  const _StaffCard({required this.member, this.onChanged});

  final StaffMember member;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            member.fullName?.isNotEmpty == true
                ? member.fullName!.substring(0, 1).toUpperCase()
                : member.email.substring(0, 1).toUpperCase(),
          ),
        ),
        title: Text(member.fullName ?? member.email),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(member.email), Text(' Â· ')],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            final repo = ref.read(staffRepositoryProvider);
            if (value.startsWith('role:')) {
              final roleValue = value.split(':').last;
              await repo.updateStaffRole(
                userId: member.id,
                role: _roleFromString(roleValue),
              );
            } else {
              await repo.updateStaffStatus(userId: member.id, status: value);
            }
            onChanged?.call();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(enabled: false, child: Text('Change role')),
            const PopupMenuItem(value: 'role:teacher', child: Text('Teacher')),
            const PopupMenuItem(value: 'role:staff', child: Text('Staff')),
            const PopupMenuItem(value: 'role:admin', child: Text('Admin')),
            const PopupMenuDivider(),
            const PopupMenuItem(enabled: false, child: Text('Status')),
            const PopupMenuItem(value: 'active', child: Text('Activate')),
            const PopupMenuItem(value: 'inactive', child: Text('Deactivate')),
            const PopupMenuItem(value: 'suspended', child: Text('Suspend')),
          ],
        ),
      ),
    );
  }

  UserRole _roleFromString(String value) {
    switch (value) {
      case 'principal':
        return UserRole.principal;
      case 'admin':
        return UserRole.admin;
      case 'teacher':
        return UserRole.teacher;
      case 'staff':
      default:
        return UserRole.staff;
    }
  }
}

class _StaffInvitesTab extends ConsumerWidget {
  const _StaffInvitesTab({
    required this.filters,
    required this.onFilterChanged,
  });

  final StaffInviteFilters filters;
  final ValueChanged<StaffInviteFilters> onFilterChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(staffInvitesProvider(filters));
    return Column(
      children: [
        _InviteFilters(filters: filters, onChanged: onFilterChanged),
        Expanded(
          child: invitesAsync.when(
            data: (invites) {
              if (invites.isEmpty) {
                return const _EmptyState(
                  icon: Icons.mail_outline,
                  title: 'No invites yet',
                  subtitle: 'Invite staff to collaborate in the portal.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: invites.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final invite = invites[index];
                  return _InviteCard(
                    invite: invite,
                    onAction: () =>
                        ref.invalidate(staffInvitesProvider(filters)),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorState(
              message: 'Unable to load invites: ',
              onRetry: () => ref.invalidate(staffInvitesProvider(filters)),
            ),
          ),
        ),
      ],
    );
  }
}

class _InviteFilters extends StatelessWidget {
  const _InviteFilters({required this.filters, required this.onChanged});

  final StaffInviteFilters filters;
  final ValueChanged<StaffInviteFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: filters.status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                  DropdownMenuItem(
                    value: 'cancelled',
                    child: Text('Cancelled'),
                  ),
                ],
                onChanged: (value) => onChanged((status: value)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCard extends ConsumerWidget {
  const _InviteCard({required this.invite, this.onAction});

  final StaffInvite invite;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = invite.status == 'pending';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.mail_outline),
        title: Text(invite.email),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(' Â· '),
            if (invite.expiresAt != null) Text('Expires '),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy invite code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: invite.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite code copied')),
                );
              },
            ),
            PopupMenuButton<String>(
              enabled: isPending,
              onSelected: (value) async {
                final repo = ref.read(staffRepositoryProvider);
                if (value == 'cancel') {
                  await repo.cancelInvite(invite.id);
                } else if (value == 'resend') {
                  await repo.resendInvite(invite.id);
                }
                onAction?.call();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'resend', child: Text('Resend')),
                PopupMenuItem(value: 'cancel', child: Text('Cancel invite')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteStaffDialog extends ConsumerStatefulWidget {
  const _InviteStaffDialog();

  @override
  ConsumerState<_InviteStaffDialog> createState() => _InviteStaffDialogState();
}

class _InviteStaffDialogState extends ConsumerState<_InviteStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  UserRole _role = UserRole.teacher;
  int? _expiresInDays = 14;
  bool _isSaving = false;
  StaffInvite? _createdInvite;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _createdInvite == null ? 'Invite Staff' : 'Invite Created',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        Navigator.of(context).pop(_createdInvite != null),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_createdInvite == null)
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserRole>(
                        initialValue: _role,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: UserRole.teacher,
                            child: Text('Teacher'),
                          ),
                          DropdownMenuItem(
                            value: UserRole.staff,
                            child: Text('Staff'),
                          ),
                          DropdownMenuItem(
                            value: UserRole.admin,
                            child: Text('Admin'),
                          ),
                          DropdownMenuItem(
                            value: UserRole.principal,
                            child: Text('Principal'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _role = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        initialValue: _expiresInDays,
                        decoration: const InputDecoration(
                          labelText: 'Expires in',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 7, child: Text('7 days')),
                          DropdownMenuItem(value: 14, child: Text('14 days')),
                          DropdownMenuItem(value: 30, child: Text('30 days')),
                          DropdownMenuItem(
                            value: null,
                            child: Text('No expiry'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _expiresInDays = value),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _createInvite,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Create Invite'),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _InviteSummary(invite: _createdInvite!),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createInvite() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(staffRepositoryProvider);
      final invitedBy = await repo.getCurrentUserRowId();
      final invite = await repo.createInvite(
        email: _emailController.text.trim(),
        role: _role,
        fullName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        expiresInDays: _expiresInDays,
        invitedByUserId: invitedBy,
      );
      setState(() {
        _createdInvite = invite;
      });
    } catch (e) {
      if (!mounted) return;
      
      // Extract user-friendly error message
      String errorMessage = 'Failed to create invite. Please try again.';
      
      // Check if it's an AppError with userMessage
      if (e is AppError && e.userMessage != null && e.userMessage!.isNotEmpty) {
        errorMessage = e.userMessage!;
      } else {
        // Try to extract meaningful message from exception string
        final errorStr = e.toString();
        // Remove "Exception: " prefix if present
        if (errorStr.startsWith('Exception: ')) {
          final msg = errorStr.substring(11);
          // Use message if it's short and meaningful
          if (msg.length < 150 && 
              (msg.contains('already exists') ||
               msg.contains('not found') ||
               msg.contains('permission') ||
               msg.contains('required'))) {
            errorMessage = msg;
          }
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _InviteSummary extends StatelessWidget {
  const _InviteSummary({required this.invite});

  final StaffInvite invite;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Share this invite code with .',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        SelectableText(
          invite.code,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: invite.code));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Invite code copied')));
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy Code'),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
