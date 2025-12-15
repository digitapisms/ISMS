import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/data/countries.dart';
import '../../../core/data/pakistan_data.dart';
import '../application/school_providers.dart';
import '../../authentication/presentation/login_screen.dart';
import 'widgets/location_picker_widget.dart';

class SchoolRegistrationScreen extends ConsumerStatefulWidget {
  const SchoolRegistrationScreen({super.key});

  @override
  ConsumerState<SchoolRegistrationScreen> createState() =>
      _SchoolRegistrationScreenState();
}

class _SchoolRegistrationScreenState
    extends ConsumerState<SchoolRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // School Information
  final _schoolNameController = TextEditingController();
  final _schoolEmailController = TextEditingController();
  final _schoolPhoneController = TextEditingController();
  final _schoolWebsiteController = TextEditingController();
  final _sloganController = TextEditingController();
  final _schoolAddressController = TextEditingController();
  final _schoolCityController = TextEditingController();
  final _schoolStateController = TextEditingController();
  final _schoolZipCodeController = TextEditingController();
  final _groupNameController = TextEditingController();
  final _boardsOrganizationsController = TextEditingController();
  
  // New contact fields
  final _phoneSecondaryController = TextEditingController();
  final _phoneLandlineController = TextEditingController();
  final _whatsappNumberController = TextEditingController();
  final _faxNumberController = TextEditingController();
  
  // Pakistan-specific fields
  final _registrationNumberController = TextEditingController();
  final _tehsilController = TextEditingController();
  final _establishedYearController = TextEditingController();
  final _totalStudentsCapacityController = TextEditingController();
  final _cnicNumberController = TextEditingController();
  final _ntnNumberController = TextEditingController();

  String? _selectedCountry = 'Pakistan';
  String? _schoolType = 'individual'; // individual, group
  String?
  _charityFoundationType; // charity_based, foundation, part_of_foundation
  Uint8List? _logoBytes;
  String? _logoFileName;
  
  // New selection fields
  String? _registrationType; // private, public, semi_private, etc.
  String? _registrationBoard;
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _mediumOfInstruction;
  List<String> _selectedEducationLevels = [];
  String? _genderType;
  
  // Location fields
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedLocationAddress;

  // Principal Information
  final _principalNameController = TextEditingController();
  final _principalEmailController = TextEditingController();
  final _principalPasswordController = TextEditingController();
  final _principalConfirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _pageController.dispose();
    _schoolNameController.dispose();
    _schoolEmailController.dispose();
    _schoolPhoneController.dispose();
    _schoolWebsiteController.dispose();
    _sloganController.dispose();
    _schoolAddressController.dispose();
    _schoolCityController.dispose();
    _schoolStateController.dispose();
    _schoolZipCodeController.dispose();
    _groupNameController.dispose();
    _boardsOrganizationsController.dispose();
    _phoneSecondaryController.dispose();
    _phoneLandlineController.dispose();
    _whatsappNumberController.dispose();
    _faxNumberController.dispose();
    _registrationNumberController.dispose();
    _tehsilController.dispose();
    _establishedYearController.dispose();
    _totalStudentsCapacityController.dispose();
    _cnicNumberController.dispose();
    _ntnNumberController.dispose();
    _principalNameController.dispose();
    _principalEmailController.dispose();
    _principalPasswordController.dispose();
    _principalConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 200,
        maxHeight: 200,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _logoBytes = bytes;
          _logoFileName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_principalPasswordController.text !=
        _principalConfirmPasswordController.text) {
      setState(() {
        _error = 'Passwords do not match';
      });
      return;
    }

    if (_schoolType == 'group' && _groupNameController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter group name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(schoolRepositoryProvider);
      await repo.registerSchool(
        name: _schoolNameController.text.trim(),
        email: _schoolEmailController.text.trim(),
        phone: _schoolPhoneController.text.trim(),
        principalName: _principalNameController.text.trim(),
        principalEmail: _principalEmailController.text.trim(),
        principalPassword: _principalPasswordController.text,
        address: _schoolAddressController.text.trim().isEmpty
            ? null
            : _schoolAddressController.text.trim(),
        city: _schoolCityController.text.trim().isEmpty
            ? null
            : _schoolCityController.text.trim(),
        state: _schoolStateController.text.trim().isEmpty
            ? null
            : _schoolStateController.text.trim(),
        zipCode: _schoolZipCodeController.text.trim().isEmpty
            ? null
            : _schoolZipCodeController.text.trim(),
        country: _selectedCountry,
        website: _schoolWebsiteController.text.trim().isEmpty
            ? null
            : _schoolWebsiteController.text.trim(),
        slogan: _sloganController.text.trim().isEmpty
            ? null
            : _sloganController.text.trim(),
        schoolType: _schoolType,
        groupName:
            _schoolType == 'group' &&
                _groupNameController.text.trim().isNotEmpty
            ? _groupNameController.text.trim()
            : null,
        boardsOrganizations: _boardsOrganizationsController.text.trim().isEmpty
            ? null
            : _boardsOrganizationsController.text.trim(),
        charityFoundationType: _charityFoundationType,
        logoBytes: _logoBytes,
        logoFileName: _logoFileName,
      );

      if (!mounted) return;

      // Show success message and navigate to login
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('Registration Successful'),
            ],
          ),
          content: const Text(
            'Your school has been registered successfully! '
            'Please check your email to verify your account, then sign in.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Registration failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.secondary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Register Your School',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance back button
                    ],
                  ),
                ),
                // Progress Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / 3,
                    backgroundColor: Colors.grey.shade200,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Step ${_currentPage + 1} of 3',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                // Form Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildSchoolInfoPage(),
                      _buildSchoolDetailsPage(),
                      _buildPrincipalInfoPage(),
                    ],
                  ),
                ),
                // Navigation Buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        OutlinedButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                            setState(() {
                              _currentPage--;
                            });
                          },
                          child: const Text('Previous'),
                        ),
                      const Spacer(),
                      if (_error != null) ...[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: colorScheme.error,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      if (_currentPage < 2)
                        FilledButton(
                          onPressed: () {
                            if (_validateCurrentPage()) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              setState(() {
                                _currentPage++;
                              });
                            }
                          },
                          child: const Text('Next'),
                        )
                      else
                        FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Register School'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'School Information',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your school basic details',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Logo Upload
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _logoBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              _logoBytes!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload Logo\n(200x200)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.upload),
                  label: Text(
                    _logoBytes != null ? 'Change Logo' : 'Upload Logo',
                  ),
                  onPressed: _pickLogo,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _schoolNameController,
            decoration: const InputDecoration(
              labelText: 'School Name *',
              prefixIcon: Icon(Icons.school),
              hintText: 'e.g., ABC International School',
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _sloganController,
            decoration: const InputDecoration(
              labelText: 'School Slogan (Optional)',
              prefixIcon: Icon(Icons.format_quote),
              hintText: 'e.g., Excellence in Education',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _schoolEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'School Email *',
              prefixIcon: Icon(Icons.email),
              hintText: 'contact@school.com',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _schoolPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Primary Phone *',
              prefixIcon: Icon(Icons.phone),
              hintText: '+92 300 1234567',
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 20),
          
          // Additional Contact Numbers
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _phoneSecondaryController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Secondary Phone',
                    prefixIcon: Icon(Icons.phone_android),
                    hintText: '+92 300 1234567',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _phoneLandlineController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Landline',
                    prefixIcon: Icon(Icons.phone_in_talk),
                    hintText: '042-1234567',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // WhatsApp Number
          TextFormField(
            controller: _whatsappNumberController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'WhatsApp Number',
              prefixIcon: Icon(Icons.chat),
              hintText: '+92 300 1234567',
              helperText: 'Include country code (e.g., +92)',
            ),
          ),
          const SizedBox(height: 20),
          
          // Fax Number
          TextFormField(
            controller: _faxNumberController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Fax Number (Optional)',
              prefixIcon: Icon(Icons.print),
              hintText: '042-1234567',
            ),
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _schoolWebsiteController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Website (Optional)',
              prefixIcon: Icon(Icons.language),
              hintText: 'https://www.school.com',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'School Details',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Additional information about your school',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // School Type
          Text('School Type *', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'individual',
                label: Text('Individual'),
                icon: Icon(Icons.school),
              ),
              ButtonSegment(
                value: 'group',
                label: Text('Part of Group'),
                icon: Icon(Icons.account_tree),
              ),
            ],
            selected: {_schoolType!},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _schoolType = newSelection.first;
                if (_schoolType == 'individual') {
                  _groupNameController.clear();
                }
              });
            },
          ),
          const SizedBox(height: 24),

          // Group Name (conditional)
          if (_schoolType == 'group') ...[
            TextFormField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name *',
                prefixIcon: Icon(Icons.account_tree),
                hintText: 'e.g., ABC Education Group',
              ),
              validator: (v) {
                if (_schoolType == 'group' && (v == null || v.isEmpty)) {
                  return 'Required for group schools';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],

          // Charity/Foundation Type
          Text(
            'Charity/Foundation Status',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _charityFoundationType,
            decoration: const InputDecoration(
              labelText: 'Select Type (Optional)',
              prefixIcon: Icon(Icons.favorite),
              hintText: 'Select if applicable',
            ),
            items: const [
              DropdownMenuItem(
                value: 'charity_based',
                child: Text('Charity Based'),
              ),
              DropdownMenuItem(value: 'foundation', child: Text('Foundation')),
              DropdownMenuItem(
                value: 'part_of_foundation',
                child: Text('Part of Foundation'),
              ),
            ],
            onChanged: (v) => setState(() => _charityFoundationType = v),
          ),
          const SizedBox(height: 24),

          // Registration Type (Pakistan-specific)
          Text(
            'School Registration Type *',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _registrationType,
            decoration: const InputDecoration(
              labelText: 'Select Registration Type',
              prefixIcon: Icon(Icons.badge),
              hintText: 'Select type',
            ),
            items: PakistanData.registrationTypes.map((type) {
              return DropdownMenuItem(
                value: type.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_'),
                child: Text(type),
              );
            }).toList(),
            onChanged: (v) => setState(() => _registrationType = v),
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 20),

          // Registration Number & Board
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _registrationNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number',
                    prefixIcon: Icon(Icons.numbers),
                    hintText: 'e.g., REG-12345',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _registrationBoard,
                  decoration: const InputDecoration(
                    labelText: 'Registration Board',
                    prefixIcon: Icon(Icons.school),
                  ),
                  items: PakistanData.registrationBoards.map((board) {
                    return DropdownMenuItem(
                      value: board,
                      child: Text(board),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _registrationBoard = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Province, District, Tehsil (Pakistan-specific)
          DropdownButtonFormField<String>(
            value: _selectedProvince,
            decoration: const InputDecoration(
              labelText: 'Province *',
              prefixIcon: Icon(Icons.map),
            ),
            items: PakistanData.provinces.map((province) {
              return DropdownMenuItem(
                value: province,
                child: Text(province),
              );
            }).toList(),
            onChanged: (v) {
              setState(() {
                _selectedProvince = v;
                _selectedDistrict = null; // Reset district when province changes
              });
            },
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: const InputDecoration(
                    labelText: 'District',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  items: _selectedProvince != null
                      ? PakistanData.getDistrictsForProvince(_selectedProvince!)
                          .map((district) {
                        return DropdownMenuItem(
                          value: district,
                          child: Text(district),
                        );
                      }).toList()
                      : [],
                  onChanged: (v) => setState(() => _selectedDistrict = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _tehsilController,
                  decoration: const InputDecoration(
                    labelText: 'Tehsil',
                    prefixIcon: Icon(Icons.place),
                    hintText: 'Tehsil name',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Medium of Instruction
          DropdownButtonFormField<String>(
            value: _mediumOfInstruction,
            decoration: const InputDecoration(
              labelText: 'Medium of Instruction',
              prefixIcon: Icon(Icons.language),
            ),
            items: PakistanData.mediumOfInstruction.map((medium) {
              return DropdownMenuItem(
                value: medium.toLowerCase().replaceAll(' ', '_').replaceAll('(', '').replaceAll(')', ''),
                child: Text(medium),
              );
            }).toList(),
            onChanged: (v) => setState(() => _mediumOfInstruction = v),
          ),
          const SizedBox(height: 20),

          // Education Levels
          Text(
            'Education Levels Offered',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PakistanData.educationLevels.map((level) {
              final isSelected = _selectedEducationLevels.contains(level);
              return FilterChip(
                label: Text(level),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedEducationLevels.add(level);
                    } else {
                      _selectedEducationLevels.remove(level);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Gender Type
          DropdownButtonFormField<String>(
            value: _genderType,
            decoration: const InputDecoration(
              labelText: 'Gender Type',
              prefixIcon: Icon(Icons.people),
            ),
            items: PakistanData.genderTypes.map((type) {
              return DropdownMenuItem(
                value: type.toLowerCase().replaceAll('-', '_'),
                child: Text(type),
              );
            }).toList(),
            onChanged: (v) => setState(() => _genderType = v),
          ),
          const SizedBox(height: 20),

          // Established Year & Capacity
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _establishedYearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Established Year',
                    prefixIcon: Icon(Icons.calendar_today),
                    hintText: 'e.g., 1990',
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final year = int.tryParse(v);
                      if (year == null || year < 1800 || year > DateTime.now().year) {
                        return 'Invalid year';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _totalStudentsCapacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Capacity',
                    prefixIcon: Icon(Icons.people_outline),
                    hintText: 'e.g., 500',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Boards/Organizations
          TextFormField(
            controller: _boardsOrganizationsController,
            decoration: const InputDecoration(
              labelText: 'O-Levels, Boards & Organizations',
              prefixIcon: Icon(Icons.verified),
              hintText: 'e.g., Cambridge, Edexcel, IB, AQA, etc.',
              helperText:
                  'List all boards and organizations your school is registered with',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 32),

          // Address Section
          Text('Address', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextFormField(
            controller: _schoolAddressController,
            decoration: const InputDecoration(
              labelText: 'Street Address',
              prefixIcon: Icon(Icons.location_on),
              hintText: 'House/Street number, area',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          
          // Google Maps Location Picker
          LocationPickerWidget(
            initialLatitude: _selectedLatitude,
            initialLongitude: _selectedLongitude,
            initialAddress: _selectedLocationAddress,
            onLocationSelected: (lat, lng, address) {
              setState(() {
                _selectedLatitude = lat;
                _selectedLongitude = lng;
                _selectedLocationAddress = address;
              });
            },
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _schoolCityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _schoolStateController,
                  decoration: const InputDecoration(
                    labelText: 'State/Province',
                    prefixIcon: Icon(Icons.map),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _schoolZipCodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Zip/Postal Code',
                    prefixIcon: Icon(Icons.pin),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCountry,
                  decoration: const InputDecoration(
                    labelText: 'Country *',
                    prefixIcon: Icon(Icons.public),
                  ),
                  items: worldCountries.map((country) {
                    return DropdownMenuItem(
                      value: country,
                      child: Text(country),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCountry = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrincipalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Principal Account',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Create the principal/admin account for your school',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          // Subscription Plan Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscription Plan',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your school will start with a FREE plan. After approval, you can upgrade to Basic, Premium, or Enterprise plans through the admin panel.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _principalNameController,
            decoration: const InputDecoration(
              labelText: 'Principal Name *',
              prefixIcon: Icon(Icons.person),
              hintText: 'Full name',
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _principalEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Principal Email *',
              prefixIcon: Icon(Icons.email),
              hintText: 'principal@school.com',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // CNIC Number (Pakistan-specific)
          TextFormField(
            controller: _cnicNumberController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Principal CNIC Number',
              prefixIcon: Icon(Icons.badge),
              hintText: '12345-1234567-1',
              helperText: 'Format: XXXXX-XXXXXXX-X',
            ),
            maxLength: 15,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          ),
          const SizedBox(height: 20),
          
          // NTN Number (Optional)
          TextFormField(
            controller: _ntnNumberController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'NTN Number (Optional)',
              prefixIcon: Icon(Icons.receipt),
              hintText: '1234567-1',
              helperText: 'National Tax Number if applicable',
            ),
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _principalPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password *',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              hintText: 'Minimum 8 characters',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 8) return 'Password must be at least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _principalConfirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password *',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v != _principalPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Card(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This account will be the principal/admin for your school. '
                      'You can create additional accounts after registration.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateCurrentPage() {
    if (_currentPage == 0) {
      if (_schoolNameController.text.trim().isEmpty ||
          _schoolEmailController.text.trim().isEmpty ||
          _schoolPhoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return false;
      }
    } else if (_currentPage == 1) {
      if (_schoolType == 'group' && _groupNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter group name')),
        );
        return false;
      }
    }
    return true;
  }
}
