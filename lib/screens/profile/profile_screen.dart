import 'package:flutter/gestures.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_petadopt/screens/adoption/my_adopted_pets_screen.dart';
import 'package:mobile_petadopt/screens/adoption/my_applications_screen.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  String? _savedAddress;
  String? _savedPhone;
  String? _savedSecondaryPhone;
  bool _isUploadingAvatar = false;

  static const List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.pets_rounded,
      'label': 'My Adopted Pets',
      'subtitle': 'Health check-ins & care hub',
    },
    {
      'icon': Icons.person_outline_rounded,
      'label': 'Edit Profile',
      'subtitle': 'Update your personal information',
    },
    {
      'icon': Icons.description_outlined,
      'label': 'My Applications',
      'subtitle': 'View all adoption requests',
    },
    {
      'icon': Icons.draw_rounded,
      'label': 'Digital Signature',
      'subtitle': 'Official on-record e-signature',
    },
    {
      'icon': Icons.favorite_border_rounded,
      'label': 'Saved Pets',
      'subtitle': 'Your favorited animals',
    },
    {
      'icon': Icons.notifications_none_rounded,
      'label': 'Notifications',
      'subtitle': 'Manage your alerts',
    },
    {
      'icon': Icons.help_outline_rounded,
      'label': 'Help & Support',
      'subtitle': 'FAQs and contact us',
    },
    {
      'icon': Icons.info_outline_rounded,
      'label': 'About CAWS',
      'subtitle': 'CDO Animal Welfare Society Inc.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await ApiService.getUser();
    final userId = user != null ? user['id'] : 'guest';
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('user_${userId}_full_address');
    final phone = prefs.getString('user_${userId}_phone') ?? (user != null ? user['phone'] as String? : null);
    final secondaryPhone = prefs.getString('user_${userId}_secondary_phone');
    if (mounted) {
      setState(() {
        _user = user;
        _savedAddress = address;
        _savedPhone = phone;
        _savedSecondaryPhone = secondaryPhone;
      });
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _showAvatarOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Change Profile Photo',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
                title: Text('Take Photo with Camera', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
                title: Text('Choose from Gallery', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      setState(() => _isUploadingAvatar = true);
      await ApiService.uploadAvatar(File(picked.path));
      await _loadUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile photo updated successfully.', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''), style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        backgroundColor: AppTheme.surface,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.settings_outlined,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 14),
            _buildNameCard(context),
            const SizedBox(height: 10),
            _buildAddressCard(context),
            const SizedBox(height: 10),
            _buildPhoneCard(context),
            const SizedBox(height: 10),
            _buildSignatureCard(context),
            const SizedBox(height: 14),
            _buildStatsRow(),
            const SizedBox(height: 16),
            _buildMenuSection(context),
            const SizedBox(height: 16),
            _buildLogoutButton(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _user?['name'] as String? ?? 'Adopter';
    final email = _user?['email'] as String? ?? 'adopter@email.com';
    final role = _user?['role'] as String? ?? 'adopter';
    final userId = _user?['id'];
    final adopterId = userId != null ? 'ADP-${userId.toString().padLeft(4, '0')}' : 'ADP-0001';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A6B72), AppTheme.primary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _showAvatarOptions,
            child: Stack(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 2.5,
                    ),
                  ),
                  child: _isUploadingAvatar
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          ),
                        )
                      : (_user != null && _user!['avatar'] != null && _user!['avatar'].toString().isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                _user!['avatar'],
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    _getInitials(name),
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                _getInitials(name),
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primary,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showEditNameDialog(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit_rounded, size: 14, color: Colors.white70),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            email,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.badge_rounded, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 5),
                    Text(
                      'ID: $adopterId',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNameCard(BuildContext context) {
    final name = _user?['name'] as String? ?? 'Not set yet';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Full Legal Name',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showEditNameDialog(context),
            child: Text(
              'Edit',
              style: GoogleFonts.poppins(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final currentName = _user?['name'] as String? ?? '';
    final nameController = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_outline_rounded, color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Edit Full Legal Name',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Please enter your full legal name as it appears on your Government ID (e.g. Juan Dela Cruz).',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Full Legal Name *',
                    hintText: 'e.g. Junar Abcede',
                    prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.textSecondary, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your full legal name';
                    if (val.trim().length < 3) return 'Name is too short';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (formKey.currentState!.validate()) {
                        setModalState(() => isSaving = true);
                        final newName = nameController.text.trim();
                        try {
                          await ApiService.updateProfileName(newName);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            await _loadUser();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Legal name updated to "$newName" successfully.', style: GoogleFonts.poppins(fontSize: 13)),
                                backgroundColor: AppTheme.successColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isSaving = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update name: $e', style: GoogleFonts.poppins(fontSize: 13)),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            'Save Full Name',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context) {
    final hasAddress = _savedAddress != null && _savedAddress!.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Location',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  hasAddress ? _savedAddress! : 'No address set yet',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasAddress ? AppTheme.textPrimary : AppTheme.errorColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final res = await Navigator.pushNamed(context, '/edit-address');
              if (res == true && mounted) {
                _loadUser();
              }
            },
            child: Text(
              hasAddress ? 'Edit' : 'Set Location',
              style: GoogleFonts.poppins(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneCard(BuildContext context) {
    final hasPhone = _savedPhone != null && _savedPhone!.trim().isNotEmpty;
    final hasSecondary = _savedSecondaryPhone != null && _savedSecondaryPhone!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.phone_iphone_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Contact Numbers',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                if (!hasPhone && !hasSecondary)
                  Text(
                    'No mobile number set yet',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.errorColor,
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Primary',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _savedPhone ?? 'None',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (hasSecondary) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Backup',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _savedSecondaryPhone!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showEditPhoneDialog(context),
            child: Text(
              hasPhone ? 'Edit' : 'Set Phone',
              style: GoogleFonts.poppins(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPhoneDialog(BuildContext context) {
    final phoneController = TextEditingController(text: _savedPhone ?? '');
    final secondaryController = TextEditingController(text: _savedSecondaryPhone ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          top: 24,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.phone_iphone_rounded, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Saved Contact Numbers',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Add your primary and optional backup contact number for adoption communications.',
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  labelText: 'Primary Mobile Number *',
                  hintText: '09123456789',
                  counterText: '',
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.textSecondary, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Primary mobile number is required';
                  final trimmed = val.trim();
                  if (!trimmed.startsWith('09') || trimmed.length != 11) {
                    return 'Must start with 09 and be 11 digits (e.g. 09123456789)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: secondaryController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  labelText: 'Secondary / Backup Number (Optional)',
                  hintText: '09987654321',
                  counterText: '',
                  prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppTheme.textSecondary, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final trimmed = val.trim();
                    if (!trimmed.startsWith('09') || trimmed.length != 11) {
                      return 'Must start with 09 and be 11 digits';
                    }
                    if (trimmed == phoneController.text.trim()) {
                      return 'Must be different from primary number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final newPhone = phoneController.text.trim();
                      final newSecondary = secondaryController.text.trim();
                      final user = await ApiService.getUser();
                      final userId = user != null ? user['id'] : 'guest';
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('user_${userId}_phone', newPhone);
                      if (newSecondary.isNotEmpty) {
                        await prefs.setString('user_${userId}_secondary_phone', newSecondary);
                      } else {
                        await prefs.remove('user_${userId}_secondary_phone');
                      }
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (mounted) {
                        setState(() {
                          _savedPhone = newPhone;
                          _savedSecondaryPhone = newSecondary.isNotEmpty ? newSecondary : null;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Contact numbers saved successfully.', style: GoogleFonts.poppins(fontSize: 13)),
                            backgroundColor: AppTheme.successColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Save Contact Numbers',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  Widget _buildSignatureCard(BuildContext context) {
    final signatureUrl = _user?['digital_signature_url']?.toString();
    final hasSignature = signatureUrl != null && signatureUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.draw_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Digital Signature',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      hasSignature ? 'Verified on Record' : 'No signature on record',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasSignature ? const Color(0xFF059669) : AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasSignature)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF059669)),
                      const SizedBox(width: 4),
                      Text(
                        'Active',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasSignature) ...[
            Container(
              height: 70,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.centerLeft,
              child: Image.network(
                signatureUrl,
                height: 58,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    'Signature on record',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _showDigitalSignatureModal(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Change Signature',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit_document, size: 14, color: Color(0xFF1D4ED8)),
                  ],
                ),
              ),
            ),
          ] else ...[
            InkWell(
              onTap: () => _showDigitalSignatureModal(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Set Signature',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.draw_rounded, size: 14, color: Color(0xFF1D4ED8)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statCard('4', 'Applications', Icons.description_outlined),
          const SizedBox(width: 10),
          _statCard('1', 'Approved', Icons.check_circle_outline_rounded),
          const SizedBox(width: 10),
          _statCard('6', 'Saved Pets', Icons.favorite_border_rounded),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: List.generate(_menuItems.length, (index) {
          final item = _menuItems[index];
          final isLast = index == _menuItems.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: () {
                  if (item['label'] == 'Edit Profile') {
                    _showEditNameDialog(context);
                  } else if (item['label'] == 'My Adopted Pets') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyAdoptedPetsScreen()),
                    );
                  } else if (item['label'] == 'My Applications') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyApplicationsScreen()),
                    );
                  } else if (item['label'] == 'Digital Signature') {
                    _showDigitalSignatureModal(context);
                  } else if (item['label'] == 'Saved Pets') {
                    Navigator.pushNamed(context, '/favorites');
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['label'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              item['subtitle'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  indent: 70,
                  color: AppTheme.cardBorder,
                ),
            ],
          );
        }),
      ),
    );
  }

  
  void _showDigitalSignatureModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DigitalSignatureSheet(
        initialSignatureUrl: _user?['digital_signature_url']?.toString(),
        onSignatureUpdated: () async {
          await _loadUser();
          if (mounted) setState(() {});
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Logout',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              content: Text(
                'Are you sure you want to logout?',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await ApiService.clearSession();
                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEEEEE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: AppTheme.errorColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Logout',
                style: GoogleFonts.poppins(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _DigitalSignatureSheet extends StatefulWidget {
  final String? initialSignatureUrl;
  final VoidCallback onSignatureUpdated;

  const _DigitalSignatureSheet({
    required this.initialSignatureUrl,
    required this.onSignatureUpdated,
  });

  @override
  State<_DigitalSignatureSheet> createState() => _DigitalSignatureSheetState();
}

class _DigitalSignatureSheetState extends State<_DigitalSignatureSheet> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _isDrawing = false;
  bool _isSaving = false;
  bool _isSigning = false;
  String? _signatureUrl;

  @override
  void initState() {
    super.initState();
    _signatureUrl = widget.initialSignatureUrl;
    if (_signatureUrl == null || _signatureUrl!.isEmpty) {
      _isDrawing = true;
    }
  }

  void _clearSignature() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  Future<String?> _exportSignatureAsBase64() async {
    if (_strokes.isEmpty) return null;

    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final stroke in _strokes) {
      for (final p in stroke) {
        if (p.dx < minX) minX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy > maxY) maxY = p.dy;
      }
    }

    const padding = 10.0;
    minX = (minX - padding).clamp(0.0, double.infinity);
    minY = (minY - padding).clamp(0.0, double.infinity);
    maxX = maxX + padding;
    maxY = maxY + padding;

    final width = (maxX - minX).clamp(60.0, 600.0);
    final height = (maxY - minY).clamp(30.0, 300.0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.5
      ..isAntiAlias = true;

    canvas.translate(-minX, -minY);

    for (final stroke in _strokes) {
      if (stroke.length > 1) {
        for (int i = 0; i < stroke.length - 1; i++) {
          canvas.drawLine(stroke[i], stroke[i + 1], paint);
        }
      } else if (stroke.length == 1) {
        canvas.drawCircle(stroke[0], 2.0, paint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final bytes = byteData.buffer.asUint8List();
    return 'data:image/png;base64,${base64Encode(bytes)}';
  }

  Future<void> _saveSignature() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw your signature before saving.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final base64Sig = await _exportSignatureAsBase64();
      if (base64Sig == null) throw Exception('Could not process signature image.');

      final res = await ApiService.updateUserSignature(signatureBase64: base64Sig);
      final newUrl = res['digital_signature_url']?.toString();

      if (mounted) {
        setState(() {
          _signatureUrl = newUrl;
          _isDrawing = false;
          _isSaving = false;
          _strokes.clear();
        });
        widget.onSignatureUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Digital signature saved to your profile on record.',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSignature = _signatureUrl != null && _signatureUrl!.isNotEmpty;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.draw_rounded, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Digital Signature',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Official e-Signature Record',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              if (hasSignature && !_isDrawing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'On Record',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (hasSignature && !_isDrawing) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    height: 130,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Image.network(
                      _signatureUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text('Signature on file', style: TextStyle(color: Color(0xFF64748B))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Your e-signature is securely saved and automatically used on your approved CAWS adoption agreements.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isDrawing = true;
                        _strokes.clear();
                      });
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primary),
                    label: Text(
                      'Update Signature',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Draw your legal signature below using your finger (eGov Standard). It will be saved on your adopter profile.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    if (_strokes.isEmpty)
                      const IgnorePointer(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.draw_rounded, size: 24, color: Color(0xFF94A3B8)),
                              SizedBox(height: 4),
                              Text(
                                'Sign inside this box',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 20,
                      left: 16,
                      right: 16,
                      child: const IgnorePointer(
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                    Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (event) {
                        setState(() {
                          _isSigning = true;
                          _currentStroke = [event.localPosition];
                          _strokes.add(_currentStroke);
                        });
                      },
                      onPointerMove: (event) {
                        setState(() {
                          _currentStroke.add(event.localPosition);
                        });
                      },
                      onPointerUp: (_) {
                        setState(() {
                          _isSigning = false;
                          _currentStroke = [];
                        });
                      },
                      child: SizedBox.expand(
                        child: CustomPaint(
                          painter: _SignaturePadPainter(strokes: _strokes),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _clearSignature,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF64748B)),
                  label: Text('Clear Pad', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
                ),
                if (hasSignature)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isDrawing = false;
                        _strokes.clear();
                      });
                    },
                    child: Text('Cancel Update', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primary)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSignature,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Save Digital Signature',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SignaturePadPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePadPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0
      ..isAntiAlias = true;

    for (final stroke in strokes) {
      if (stroke.length > 1) {
        for (int i = 0; i < stroke.length - 1; i++) {
          canvas.drawLine(stroke[i], stroke[i + 1], paint);
        }
      } else if (stroke.length == 1) {
        canvas.drawCircle(stroke[0], 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePadPainter oldDelegate) => true;
}
