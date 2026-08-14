import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/data/philippine_locations.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditAddressScreen extends StatefulWidget {
  const EditAddressScreen({super.key});

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();

  String _selectedCity = 'Cagayan de Oro City';
  String _selectedBarangay = 'Carmen';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingAddress();
  }

  @override
  void dispose() {
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingAddress() async {
    final user = await ApiService.getUser();
    final userId = user != null ? user['id'] : 'guest';
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('user_${userId}_city');
    final barangay = prefs.getString('user_${userId}_barangay');
    final street = prefs.getString('user_${userId}_street');

    if (mounted && city != null) {
      setState(() {
        if (LocationData.citiesAndMunicipalities.contains(city)) {
          _selectedCity = city;
        }

        final availableBarangays = LocationData.getBarangays(_selectedCity);
        if (barangay != null && availableBarangays.contains(barangay)) {
          _selectedBarangay = barangay;
        } else if (availableBarangays.isNotEmpty) {
          _selectedBarangay = availableBarangays.first;
        }

        if (street != null) {
          _streetController.text = street;
        }
      });
    }
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final finalStreet = _streetController.text.trim();
      final fullAddress = '$finalStreet, Brgy. $_selectedBarangay, $_selectedCity, ${LocationData.defaultProvince}';

      final user = await ApiService.getUser();
      final userId = user != null ? user['id'] : 'guest';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_${userId}_city', _selectedCity);
      await prefs.setString('user_${userId}_barangay', _selectedBarangay);
      await prefs.setString('user_${userId}_street', finalStreet);
      await prefs.setString('user_${userId}_full_address', fullAddress);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Address saved successfully.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableBarangays = LocationData.getBarangays(_selectedCity);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Text(
          'Set Saved Address',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Official Residence Address',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          Text(
                            'Select your municipality and barangay from the official list below.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Province',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Text(
                  LocationData.defaultProvince,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'City / Municipality',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: LocationData.citiesAndMunicipalities.contains(_selectedCity)
                    ? _selectedCity
                    : LocationData.citiesAndMunicipalities.first,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.location_city_rounded,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
                items: LocationData.citiesAndMunicipalities.map((city) {
                  return DropdownMenuItem(
                    value: city,
                    child: Text(
                      city,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCity = val;
                      final newBarangays = LocationData.getBarangays(val);
                      _selectedBarangay = newBarangays.first;
                    });
                  }
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Barangay (${availableBarangays.length} Official Barangays)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: availableBarangays.contains(_selectedBarangay)
                    ? _selectedBarangay
                    : availableBarangays.first,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.map_rounded,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
                items: availableBarangays.map((bgyn) {
                  return DropdownMenuItem(
                    value: bgyn,
                    child: Text(
                      bgyn,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedBarangay = val);
                  }
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Street Address / House # / Zone / Landmark',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _streetController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. House #123, Zone 4, Near Shell Station',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Icon(
                      Icons.home_outlined,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Please enter street address' : null,
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _isLoading ? null : _saveAddress,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryDark, AppTheme.primary],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Save Address',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
