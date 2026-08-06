import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  static const List<Map<String, dynamic>> _menuItems = [
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
    if (mounted) {
      setState(() {
        _user = user;
        _savedAddress = address;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
            _buildAddressCard(context),
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
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Text('👤', style: TextStyle(fontSize: 36)),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 13,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🐾 ${role.toUpperCase()} ACCOUNT',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
                onTap: () {},
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
