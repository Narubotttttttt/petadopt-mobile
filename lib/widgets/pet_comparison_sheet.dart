import 'package:flutter/material.dart';
import 'package:mobile_petadopt/screens/recommendation/pet_comparison_chat_screen.dart';

class PetComparisonSheet {
  static Future<void> show({
    required BuildContext context,
    required List<Map<String, dynamic>> pets,
    Map<String, dynamic>? comparativeAnalysis,
    required Function(List<Map<String, dynamic>> selectedPets) onApply,
  }) {
    return PetComparisonChatScreen.navigate(
      context: context,
      pets: pets,
      comparativeAnalysis: comparativeAnalysis,
      onApply: onApply,
    );
  }
}
