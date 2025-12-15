import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget for picking school location using Google Maps
class LocationPickerWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final Function(double latitude, double longitude, String address)? onLocationSelected;

  const LocationPickerWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    this.onLocationSelected,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAddress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLatitude = widget.initialLatitude;
      _selectedLongitude = widget.initialLongitude;
      _selectedAddress = widget.initialAddress;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      // Use HTML5 geolocation API for web, or location package for mobile
      // For now, show a dialog to enter coordinates manually
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _LocationInputDialog(
          initialLat: _selectedLatitude,
          initialLng: _selectedLongitude,
        ),
      );
      
      if (result != null) {
        setState(() {
          _selectedLatitude = result['latitude'] as double;
          _selectedLongitude = result['longitude'] as double;
          _selectedAddress = result['address'] as String?;
          _isLoading = false;
        });
        
        widget.onLocationSelected?.call(
          _selectedLatitude!,
          _selectedLongitude!,
          _selectedAddress ?? '',
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  Future<void> _openGoogleMaps() async {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$_selectedLatitude,$_selectedLongitude',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'School Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _getCurrentLocation,
              tooltip: 'Use Current Location',
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: _openGoogleMaps,
              tooltip: 'Open in Google Maps',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _selectedLatitude == null || _selectedLongitude == null
                ? Center(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_off, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Select location on map or enter coordinates',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _getCurrentLocation,
                                icon: const Icon(Icons.my_location),
                                label: const Text('Select Location'),
                              ),
                            ],
                          ),
                  )
                : Stack(
                    children: [
                      // Placeholder for Google Maps - in production, use google_maps_flutter
                      Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Location Selected',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Lat: ${_selectedLatitude!.toStringAsFixed(6)}\nLng: ${_selectedLongitude!.toStringAsFixed(6)}',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _openGoogleMaps,
                                child: const Text('View in Google Maps'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
          ),
        ),
        if (_selectedAddress != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedAddress!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _getCurrentLocation,
          icon: const Icon(Icons.search),
          label: const Text('Enter Location'),
        ),
      ],
    );
  }
}

class _LocationInputDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const _LocationInputDialog({
    this.initialLat,
    this.initialLng,
  });

  @override
  State<_LocationInputDialog> createState() => _LocationInputDialogState();
}

class _LocationInputDialogState extends State<_LocationInputDialog> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null) {
      _latController.text = widget.initialLat!.toStringAsFixed(6);
    }
    if (widget.initialLng != null) {
      _lngController.text = widget.initialLng!.toStringAsFixed(6);
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Location'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Enter full address',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        prefixIcon: Icon(Icons.navigation),
                        hintText: '31.5204',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final lat = double.tryParse(v);
                        if (lat == null || lat < -90 || lat > 90) {
                          return 'Invalid latitude';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        prefixIcon: Icon(Icons.navigation),
                        hintText: '74.3587',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final lng = double.tryParse(v);
                        if (lng == null || lng < -180 || lng > 180) {
                          return 'Invalid longitude';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () async {
                  final url = Uri.parse('https://www.google.com/maps');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.map),
                label: const Text('Open Google Maps to find coordinates'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'latitude': double.parse(_latController.text),
                'longitude': double.parse(_lngController.text),
                'address': _addressController.text.trim().isEmpty
                    ? null
                    : _addressController.text.trim(),
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

