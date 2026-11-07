import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/screens/adoption/pet_medical_card_screen.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';

class AdoptedPetHubScreen extends StatelessWidget {
  final Map<String, dynamic> application;

  const AdoptedPetHubScreen({
    super.key,
    required this.application,
  });

  @override
  Widget build(BuildContext context) {
    final shelterId = application['shelterPetId'] ?? application['pet_id'] ?? application['petId'] ?? application['pet']?['id'];
    final shelterCode = application['shelterPetCode']?.toString() ?? (shelterId != null ? 'Pet no. $shelterId' : 'Pet');
    final rawName = application['petName']?.toString();
    final petName = (rawName != null && rawName.isNotEmpty && rawName.toLowerCase() != 'adopted pet')
        ? rawName
        : shelterCode;
    final petImage = application['petImage'] as String? ?? '';

    final isFinalized = application['is_finalized'] == true ||
        application['isFinalized'] == true ||
        application['contract_unlocked'] == true;

    if (!isFinalized) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(
            petName,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    size: 56,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Health Hub Locked',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'The Pet Health Hub unlocks once CAWS staff physically verifies your identification documents and completes the pet handover at the scheduled event.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white),
                  label: Text(
                    'Back to Applications',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final petId = (application['pet_id'] ??
        application['petId'] ??
        application['pet']?['id'] ??
        application['shelterPetId']) as int? ?? 0;

    return PetMedicalCardScreen(
      petId: petId,
      applicationId: (application['id'] as num?)?.toInt(),
      petName: petName,
      petImage: petImage,
    );
  }
}
