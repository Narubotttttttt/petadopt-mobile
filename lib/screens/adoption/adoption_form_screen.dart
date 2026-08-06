import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_petadopt/screens/adoption/my_applications_screen.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdoptionFormScreen extends StatefulWidget {
  final Map<String, dynamic> pet;

  const AdoptionFormScreen({super.key, required this.pet});

  @override
  State<AdoptionFormScreen> createState() => _AdoptionFormScreenState();
}

class _AdoptionFormScreenState extends State<AdoptionFormScreen> {
  int _currentStep = 0;
  final _personalFormKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _reasonController = TextEditingController();
  final _otherPetsDetailsController = TextEditingController();
  final _proposedPetNameController = TextEditingController();

  String _homeType = 'House';
  bool _hasOtherPets = false;
  bool _hasExperience = false;

  XFile? _validIdImage;
  XFile? _certificateImage;

  final ImagePicker _picker = ImagePicker();
  final List<String> _homeTypes = ['House', 'Apartment', 'Condo', 'Farm'];

  @override
  void initState() {
    super.initState();
    _loadUserAndAddress();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _reasonController.dispose();
    _otherPetsDetailsController.dispose();
    _proposedPetNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndAddress() async {
    final user = await ApiService.getUser();
    final userId = user != null ? user['id'] : 'guest';
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('user_${userId}_full_address');

    if (mounted) {
      setState(() {
        if (user != null && user['name'] != null) {
          _fullNameController.text = user['name'] as String;
        }
        if (address != null && address.isNotEmpty) {
          _addressController.text = address;
        }
      });
    }
  }

  Future<void> _pickImage(ImageSource source, bool isValidId) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          if (isValidId) {
            _validIdImage = picked;
          } else {
            _certificateImage = picked;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showImagePickerSheet(bool isValidId) {
    final title = isValidId ? 'Upload Valid Government ID' : 'Upload Barangay Certificate';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
              title: Text('Take Photo with Camera', style: GoogleFonts.poppins(fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera, isValidId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
              title: Text('Choose from Gallery', style: GoogleFonts.poppins(fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery, isValidId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0 && _personalFormKey.currentState!.validate()) {
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      if (_validIdImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please upload a photo of your Valid Government ID',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
      if (_certificateImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please upload a photo of your Barangay Certificate',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _submitForm() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );

    try {
      final petId = widget.pet['id'];
      final user = await ApiService.getUser();
      final userId = user != null ? user['id'] : 'guest';
      final prefs = await SharedPreferences.getInstance();
      final city = prefs.getString('user_${userId}_city') ?? '';
      final barangay = prefs.getString('user_${userId}_barangay') ?? '';

      await ApiService.submitAdoptionApplication(
        data: {
          'pet_id': petId,
          'full_name': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'city': city,
          'barangay': barangay,
          'home_type': _homeType,
          'has_other_pets': _hasOtherPets,
          'other_pets_details': _hasOtherPets ? _otherPetsDetailsController.text.trim() : null,
          'has_experience': _hasExperience,
          'proposed_pet_name': _proposedPetNameController.text.trim(),
          'reason': _reasonController.text.trim(),
        },
        validIdPath: _validIdImage?.path,
        certificatePath: _certificateImage?.path,
      );

      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🐾', style: TextStyle(fontSize: 34)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Adoption Request Submitted! 🐾',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your adoption request for ${widget.pet['name']} has been submitted! Please wait for approval as CAWS is verifying your documents and information.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.popUntil(context, ModalRoute.withName('/home'));
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppTheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Home',
                            style: GoogleFonts.poppins(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.popUntil(context, ModalRoute.withName('/home'));
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyApplicationsScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'My Applications',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Text(
          'Adoption Application',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildPetSummary(),
                  const SizedBox(height: 24),
                  if (_currentStep == 0) _buildStep1(),
                  if (_currentStep == 1) _buildStep2(),
                  if (_currentStep == 2) _buildStep3(),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      if (_currentStep > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _prevStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Back',
                              style: GoogleFonts.poppins(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: _currentStep == 2 ? _submitForm : _nextStep,
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryDark, AppTheme.primary],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _currentStep == 2 ? 'Submit Application' : 'Next',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Personal Info', 'Documents', 'Lifestyle'];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorder),
        ),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isDone = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDone || isActive
                            ? AppTheme.primary
                            : AppTheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone || isActive
                              ? AppTheme.primary
                              : AppTheme.cardBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: index < _currentStep
                          ? AppTheme.primary
                          : AppTheme.cardBorder,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPetSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              widget.pet['image'] as String,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 54,
                height: 54,
                color: AppTheme.primaryLight,
                child: const Center(
                  child: Text('🐾', style: TextStyle(fontSize: 22)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Applying for ${widget.pet['name']}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDark,
                ),
              ),
              Text(
                '${widget.pet['breed']} • ${widget.pet['age']} • ${widget.pet['gender']}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _personalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline_rounded,
                  color: AppTheme.textSecondary, size: 20),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined,
                  color: AppTheme.textSecondary, size: 20),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter your phone' : null,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved Residence Location',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              TextButton(
                onPressed: () async {
                  final res = await Navigator.pushNamed(context, '/edit-address');
                  if (res == true && mounted) {
                    _loadUserAndAddress();
                  }
                },
                child: Text(
                  'Change',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Complete Address',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on_outlined,
                    color: AppTheme.textSecondary, size: 20),
              ),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Please set your location' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Verification',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Please upload photos of your Valid Government ID and Barangay Certificate for adoption screening.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        _buildUploadBox(
          title: 'Valid Government ID',
          buttonText: 'Tap to upload Valid ID',
          icon: Icons.badge_outlined,
          image: _validIdImage,
          onTap: () => _showImagePickerSheet(true),
          onRemove: () => setState(() => _validIdImage = null),
        ),
        const SizedBox(height: 16),
        _buildUploadBox(
          title: 'Barangay Certificate',
          buttonText: 'Tap to upload Barangay Certificate',
          icon: Icons.description_outlined,
          image: _certificateImage,
          onTap: () => _showImagePickerSheet(false),
          onRemove: () => setState(() => _certificateImage = null),
        ),
      ],
    );
  }

  Widget _buildUploadBox({
    required String title,
    required String buttonText,
    required IconData icon,
    required XFile? image,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 135,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: image != null ? AppTheme.primary : AppTheme.cardBorder,
                width: image != null ? 2 : 1,
              ),
            ),
            child: image != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: kIsWeb
                            ? Image.network(image.path, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                            : Image.file(File(image.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        buttonText,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Lifestyle & Preferences',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Proposed New Name for ${widget.pet['name']} (Optional)',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _proposedPetNameController,
          decoration: const InputDecoration(
            hintText: 'e.g. Max, Milo, Bella',
            prefixIcon: Icon(
              Icons.label_outline_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Type of Home',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: _homeTypes.map((type) {
            final isSelected = _homeType == type;
            return GestureDetector(
              onTap: () => setState(() => _homeType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
                  ),
                ),
                child: Text(
                  type,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _toggleItem(
          'Do you have other pets at home?',
          _hasOtherPets,
          (val) => setState(() => _hasOtherPets = val),
        ),
        if (_hasOtherPets) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextFormField(
              controller: _otherPetsDetailsController,
              decoration: const InputDecoration(
                labelText: 'Details of Other Pets',
                hintText: 'e.g. 2 dogs (1 Shih Tzu, 1 Aspin), 1 Cat',
                prefixIcon: Icon(
                  Icons.pets_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              validator: (val) {
                if (_hasOtherPets && (val == null || val.trim().isEmpty)) {
                  return 'Please specify how many and what kind of pets';
                }
                return null;
              },
            ),
          ),
        ],
        const SizedBox(height: 10),
        _toggleItem(
          'Do you have experience owning pets?',
          _hasExperience,
          (val) => setState(() => _hasExperience = val),
        ),
        const SizedBox(height: 16),
        Text(
          'Why do you want to adopt ${widget.pet['name']}?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reasonController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tell us why you are the right fit...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.cardBorder),
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggleItem(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}
