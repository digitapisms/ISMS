import 'package:flutter/material.dart';

import '../domain/user_role.dart';
import 'signup_screen.dart';

class RegistrationTypeScreen extends StatelessWidget {
  const RegistrationTypeScreen({super.key});

  void _openSignup(BuildContext context, UserRole role) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SignupScreen(role: role)));
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Teacher',
        'Register as a teacher',
        Icons.person_outline,
        UserRole.teacher,
      ),
      (
        'Admin / Staff',
        'Register as admin or staff',
        Icons.admin_panel_settings_outlined,
        UserRole.staff,
      ),
      (
        'Parent',
        'Register as a parent/guardian',
        Icons.family_restroom_outlined,
        UserRole.parent,
      ),
      (
        'Student',
        'Existing student account',
        Icons.school_outlined,
        UserRole.student,
      ),
      (
        'New Student Application',
        'Apply for admission as a new student',
        Icons.app_registration_outlined,
        UserRole.applicant,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Choose account type')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            itemBuilder: (context, index) {
              final (title, subtitle, icon, role) = items[index];
              return ListTile(
                leading: Icon(icon),
                title: Text(title),
                subtitle: Text(subtitle),
                trailing: const Icon(Icons.chevron_right),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => _openSignup(context, role),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: items.length,
          ),
        ),
      ),
    );
  }
}
