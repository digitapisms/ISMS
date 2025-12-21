import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../school_registration/application/school_providers.dart';
import '../../staff_management/data/staff_repository.dart';
import '../application/auth_providers.dart';
import '../domain/user_role.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _staffInviteCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;
  String? _selectedSchoolId;
  final _schoolCodeController = TextEditingController();
  bool _validatingCode = false;
  String? _schoolName; // Show school name when code is validated
  String? _schoolCodeError; // Error message for school code validation
  bool _validatingInvite = false;
  Map<String, dynamic>? _inviteDetails;
  String? _inviteError;

  // Roles that require school selection
  bool get _requiresSchoolSelection =>
      widget.role == UserRole.applicant ||
      widget.role == UserRole.student ||
      widget.role == UserRole.parent ||
      widget.role == UserRole.teacher ||
      widget.role == UserRole.staff;

  // Teacher and staff roles can use invite codes
  bool get _requiresStaffInvite =>
      widget.role == UserRole.staff || widget.role == UserRole.teacher;

  @override
  void initState() {
    super.initState();
    // Only listen to school code validation if NOT using invite-based signup
    if (!_requiresStaffInvite) {
      _schoolCodeController.addListener(_validateSchoolCode);
    }
    _emailController.addListener(_maybeRevalidateInvite);
    _staffInviteCodeController.addListener(_validateStaffInvite);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _schoolCodeController.dispose();
    _staffInviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _validateSchoolCode() async {
    // Skip school code validation if invite is already validated (invite sets the school)
    if (_requiresStaffInvite && _inviteDetails != null) {
      return;
    }

    final code = _schoolCodeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() {
        // Don't clear school ID if it was set by invite
        if (!(_requiresStaffInvite && _inviteDetails != null)) {
          _selectedSchoolId = null;
          _schoolName = null;
        }
        _schoolCodeError = null;
      });
      return;
    }

    if (code.length < 4) {
      setState(() {
        _schoolCodeError = null;
      });
      return; // Wait for more characters
    }

    setState(() {
      _validatingCode = true;
      _schoolCodeError = null;
    });

    try {
      final repo = ref.read(schoolRepositoryProvider);
      final school = await repo.getSchoolByCode(code);

      setState(() {
        if (school != null) {
          _selectedSchoolId = school.id;
          _schoolName = school.name;
          _schoolCodeError = null;
        } else {
          // Only clear if not set by invite
          if (!(_requiresStaffInvite && _inviteDetails != null)) {
            _selectedSchoolId = null;
            _schoolName = null;
          }
          _schoolCodeError = 'School code not found or school is not active';
        }
        _validatingCode = false;
      });
    } catch (e) {
      setState(() {
        // Only clear if not set by invite
        if (!(_requiresStaffInvite && _inviteDetails != null)) {
          _selectedSchoolId = null;
          _schoolName = null;
        }
        _schoolCodeError = 'Error validating school code: ${e.toString()}';
        _validatingCode = false;
      });
    }
  }

  void _maybeRevalidateInvite() {
    // This is called when email changes via listener
    // Validation will also be triggered via onChanged in the TextFormField
  }

  Future<void> _validateStaffInvite() async {
    if (!_requiresStaffInvite) return;
    final code = _staffInviteCodeController.text.trim();
    final email = _emailController.text.trim();

    if (code.isEmpty || email.isEmpty) {
      setState(() {
        _inviteDetails = null;
        _inviteError = null;
      });
      return;
    }

    setState(() {
      _validatingInvite = true;
      _inviteError = null;
    });

    try {
      final repo = StaffRepository();
      final result = await repo.validateInvite(code: code, email: email);
      setState(() {
        _inviteDetails = result;
        if (result != null) {
          _selectedSchoolId = result['school_id'] as String?;
          _schoolName = result['school_name'] as String?;
          // Clear school code error and any previous school code input since invite sets the school
          _schoolCodeError = null;
          _schoolCodeController.clear(); // Clear any school code input
        } else {
          // Invite validation failed - clear school info
          _selectedSchoolId = null;
          _schoolName = null;
        }
        _inviteError = result == null
            ? 'Invite not found or invalid for this email'
            : null;
        _validatingInvite = false;
      });
    } catch (e) {
      setState(() {
        _validatingInvite = false;
        _inviteDetails = null;
        _inviteError = 'Unable to validate invite: $e';
      });
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_requiresSchoolSelection && _selectedSchoolId == null) {
      setState(() {
        _error = 'Please select a school';
      });
      return;
    }

    if (_requiresStaffInvite && _inviteDetails == null) {
      setState(() {
        _error = 'A valid invite code is required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: widget.role,
        schoolId: _selectedSchoolId,
      );

      if (_requiresStaffInvite) {
        final staffRepo = StaffRepository();
        await staffRepo.consumeInvite(_staffInviteCodeController.text.trim());
      }
      if (!mounted) return;
      // Go back to the first route (login screen)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      // Extract a cleaner error message
      String errorMessage = e.toString();
      // Remove "Exception: " prefix if present
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      // If the message already includes helpful text, use it as-is
      // Otherwise, prepend "Sign up failed: "
      if (!errorMessage.toLowerCase().contains('already exists') &&
          !errorMessage.toLowerCase().contains('sign in')) {
        errorMessage = 'Sign up failed: $errorMessage';
      }

      setState(() {
        _error = errorMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getRoleDescription() {
    switch (widget.role) {
      case UserRole.applicant:
        return 'Select the school you want to apply to';
      case UserRole.student:
        return 'Select your school';
      case UserRole.parent:
        return 'Select your child\'s school';
      case UserRole.teacher:
        return _requiresStaffInvite
            ? 'Enter your teacher invite code'
            : 'Select the school where you teach';
      case UserRole.staff:
        return 'Enter your staff invite code';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sign up as ${_getRoleName(widget.role)}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (_requiresSchoolSelection) ...[
                        const SizedBox(height: 8),
                        Text(
                          _getRoleDescription(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_requiresSchoolSelection &&
                          !_requiresStaffInvite) ...[
                        // Only show school code field if NOT using invite (teacher/staff use invite instead)
                        TextFormField(
                          controller: _schoolCodeController,
                          decoration: InputDecoration(
                            labelText: 'School Code',
                            hintText: 'Enter your school code',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.vpn_key),
                            suffixIcon: _validatingCode
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : _selectedSchoolId != null
                                ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                            helperText:
                                'Ask your school administrator for the registration code',
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            if (_requiresSchoolSelection) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your school code';
                              }
                              if (_selectedSchoolId == null) {
                                return 'Invalid school code. Please check and try again.';
                              }
                            }
                            return null;
                          },
                        ),
                        if (_schoolCodeError != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _schoolCodeError!,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_schoolName != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.school,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _schoolName!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                      if (_requiresStaffInvite) ...[
                        // Show invite code field first for teacher/staff signups
                        TextFormField(
                          controller: _staffInviteCodeController,
                          decoration: InputDecoration(
                            labelText: widget.role == UserRole.teacher
                                ? 'Teacher Invite Code'
                                : 'Staff Invite Code',
                            prefixIcon: const Icon(Icons.badge),
                            suffixIcon: _validatingInvite
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : _inviteDetails != null
                                ? Icon(
                                    Icons.verified,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                            helperText:
                                'Enter the invite code shared by your administrator',
                          ),
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (value) {
                            // Trigger validation when text changes
                            if (value.trim().isNotEmpty &&
                                _emailController.text.trim().isNotEmpty) {
                              _validateStaffInvite();
                            }
                          },
                          validator: (value) {
                            if (_requiresStaffInvite) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Invite code required';
                              }
                              if (_inviteDetails == null) {
                                return _inviteError ?? 'Invalid invite code';
                              }
                            }
                            return null;
                          },
                        ),
                        if (_inviteError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _inviteError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        // Show school name when invite is validated (for invite-based signups)
                        if (_inviteDetails != null && _schoolName != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.school,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _schoolName!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          // Revalidate invite when email changes (if invite code is already entered)
                          if (_requiresStaffInvite &&
                              _staffInviteCodeController.text
                                  .trim()
                                  .isNotEmpty &&
                              value.trim().isNotEmpty) {
                            _validateStaffInvite();
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _isLoading ? null : _signUp,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Sign Up'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.applicant:
        return 'Applicant';
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.staff:
        return 'Staff';
      case UserRole.admin:
        return 'Admin';
      case UserRole.principal:
        return 'Principal';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }
}
