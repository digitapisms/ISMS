import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/tenant/tenant_context.dart';
import '../../../school_registration/application/school_providers.dart';
import '../../../school_registration/domain/school.dart';

class GeneralInfoTab extends ConsumerStatefulWidget {
  const GeneralInfoTab({super.key, required this.school});

  final School school;

  @override
  ConsumerState<GeneralInfoTab> createState() => _GeneralInfoTabState();
}

class _GeneralInfoTabState extends ConsumerState<GeneralInfoTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  late TextEditingController _websiteController;
  late TextEditingController _sloganController;
  late TextEditingController _groupNameController;
  late TextEditingController _boardsController;

  String? _selectedCountry;
  String? _selectedSchoolType;
  String? _selectedCharityType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.school.name);
    _emailController = TextEditingController(text: widget.school.email);
    _phoneController = TextEditingController(text: widget.school.phone);
    _addressController = TextEditingController(
      text: widget.school.address ?? '',
    );
    _cityController = TextEditingController(text: widget.school.city ?? '');
    _stateController = TextEditingController(text: widget.school.state ?? '');
    _zipCodeController = TextEditingController(
      text: widget.school.zipCode ?? '',
    );
    _websiteController = TextEditingController(
      text: widget.school.website ?? '',
    );
    _sloganController = TextEditingController(text: widget.school.slogan ?? '');
    _groupNameController = TextEditingController(
      text: widget.school.groupName ?? '',
    );
    _boardsController = TextEditingController(
      text: widget.school.boardsOrganizations ?? '',
    );

    _selectedCountry = widget.school.country ?? 'Pakistan';
    _selectedSchoolType = widget.school.schoolType;
    _selectedCharityType = widget.school.charityFoundationType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _websiteController.dispose();
    _sloganController.dispose();
    _groupNameController.dispose();
    _boardsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(schoolRepositoryProvider);
      await repo.updateSchool(
        schoolId: widget.school.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty
            ? null
            : _stateController.text.trim(),
        zipCode: _zipCodeController.text.trim().isEmpty
            ? null
            : _zipCodeController.text.trim(),
        country: _selectedCountry,
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        slogan: _sloganController.text.trim().isEmpty
            ? null
            : _sloganController.text.trim(),
        schoolType: _selectedSchoolType,
        groupName: _selectedSchoolType == 'group'
            ? (_groupNameController.text.trim().isEmpty
                  ? null
                  : _groupNameController.text.trim())
            : null,
        boardsOrganizations: _boardsController.text.trim().isEmpty
            ? null
            : _boardsController.text.trim(),
        charityFoundationType: _selectedCharityType,
      );

      // Refresh school data
      ref.invalidate(schoolProvider(widget.school.id));
      ref.invalidate(currentSchoolProvider);

      // Update tenant context
      final updatedSchool = await repo.getSchoolById(widget.school.id);
      if (updatedSchool != null) {
        ref.read(tenantContextProvider.notifier).setSchool(updatedSchool);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('School information updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Information',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Update your school\'s basic information and contact details.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'School Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'School name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone is required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sloganController,
              decoration: const InputDecoration(
                labelText: 'Slogan',
                hintText: 'Your school\'s motto or slogan',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State/Province',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _zipCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Zip/Postal Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCountry,
                    decoration: const InputDecoration(
                      labelText: 'Country *',
                      border: OutlineInputBorder(),
                    ),
                    items: _getCountries().map((country) {
                      return DropdownMenuItem(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCountry = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            Text(
              'School Type',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedSchoolType,
              decoration: const InputDecoration(
                labelText: 'School Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'individual',
                  child: Text('Individual'),
                ),
                DropdownMenuItem(value: 'group', child: Text('Part of Group')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSchoolType = value;
                });
              },
            ),
            if (_selectedSchoolType == 'group') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_selectedSchoolType == 'group' &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Group name is required';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Boards & Organizations',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _boardsController,
              decoration: const InputDecoration(
                labelText: 'O-Levels, Boards, Organizations',
                hintText: 'e.g., Cambridge, Edexcel, AQA, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Charity/Foundation Status',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCharityType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('None')),
                DropdownMenuItem(
                  value: 'charity_based',
                  child: Text('Charity Based'),
                ),
                DropdownMenuItem(
                  value: 'foundation',
                  child: Text('Foundation'),
                ),
                DropdownMenuItem(
                  value: 'part_of_foundation',
                  child: Text('Part of Foundation'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCharityType = value;
                });
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getCountries() {
    // Comprehensive list of all countries
    return [
      'Afghanistan',
      'Albania',
      'Algeria',
      'Andorra',
      'Angola',
      'Antigua and Barbuda',
      'Argentina',
      'Armenia',
      'Australia',
      'Austria',
      'Azerbaijan',
      'Bahamas',
      'Bahrain',
      'Bangladesh',
      'Barbados',
      'Belarus',
      'Belgium',
      'Belize',
      'Benin',
      'Bhutan',
      'Bolivia',
      'Bosnia and Herzegovina',
      'Botswana',
      'Brazil',
      'Brunei',
      'Bulgaria',
      'Burkina Faso',
      'Burundi',
      'Cabo Verde',
      'Cambodia',
      'Cameroon',
      'Canada',
      'Central African Republic',
      'Chad',
      'Chile',
      'China',
      'Colombia',
      'Comoros',
      'Congo',
      'Costa Rica',
      'Croatia',
      'Cuba',
      'Cyprus',
      'Czech Republic',
      'Denmark',
      'Djibouti',
      'Dominica',
      'Dominican Republic',
      'Ecuador',
      'Egypt',
      'El Salvador',
      'Equatorial Guinea',
      'Eritrea',
      'Estonia',
      'Eswatini',
      'Ethiopia',
      'Fiji',
      'Finland',
      'France',
      'Gabon',
      'Gambia',
      'Georgia',
      'Germany',
      'Ghana',
      'Greece',
      'Grenada',
      'Guatemala',
      'Guinea',
      'Guinea-Bissau',
      'Guyana',
      'Haiti',
      'Honduras',
      'Hungary',
      'Iceland',
      'India',
      'Indonesia',
      'Iran',
      'Iraq',
      'Ireland',
      'Israel',
      'Italy',
      'Jamaica',
      'Japan',
      'Jordan',
      'Kazakhstan',
      'Kenya',
      'Kiribati',
      'Kosovo',
      'Kuwait',
      'Kyrgyzstan',
      'Laos',
      'Latvia',
      'Lebanon',
      'Lesotho',
      'Liberia',
      'Libya',
      'Liechtenstein',
      'Lithuania',
      'Luxembourg',
      'Madagascar',
      'Malawi',
      'Malaysia',
      'Maldives',
      'Mali',
      'Malta',
      'Marshall Islands',
      'Mauritania',
      'Mauritius',
      'Mexico',
      'Micronesia',
      'Moldova',
      'Monaco',
      'Mongolia',
      'Montenegro',
      'Morocco',
      'Mozambique',
      'Myanmar',
      'Namibia',
      'Nauru',
      'Nepal',
      'Netherlands',
      'New Zealand',
      'Nicaragua',
      'Niger',
      'Nigeria',
      'North Korea',
      'North Macedonia',
      'Norway',
      'Oman',
      'Pakistan',
      'Palau',
      'Palestine',
      'Panama',
      'Papua New Guinea',
      'Paraguay',
      'Peru',
      'Philippines',
      'Poland',
      'Portugal',
      'Qatar',
      'Romania',
      'Russia',
      'Rwanda',
      'Saint Kitts and Nevis',
      'Saint Lucia',
      'Saint Vincent and the Grenadines',
      'Samoa',
      'San Marino',
      'Sao Tome and Principe',
      'Saudi Arabia',
      'Senegal',
      'Serbia',
      'Seychelles',
      'Sierra Leone',
      'Singapore',
      'Slovakia',
      'Slovenia',
      'Solomon Islands',
      'Somalia',
      'South Africa',
      'South Korea',
      'South Sudan',
      'Spain',
      'Sri Lanka',
      'Sudan',
      'Suriname',
      'Sweden',
      'Switzerland',
      'Syria',
      'Taiwan',
      'Tajikistan',
      'Tanzania',
      'Thailand',
      'Timor-Leste',
      'Togo',
      'Tonga',
      'Trinidad and Tobago',
      'Tunisia',
      'Turkey',
      'Turkmenistan',
      'Tuvalu',
      'Uganda',
      'Ukraine',
      'United Arab Emirates',
      'United Kingdom',
      'United States',
      'Uruguay',
      'Uzbekistan',
      'Vanuatu',
      'Vatican City',
      'Venezuela',
      'Vietnam',
      'Yemen',
      'Zambia',
      'Zimbabwe',
    ];
  }
}
