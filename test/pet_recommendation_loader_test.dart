import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_petadopt/widgets/pet_recommendation_loader.dart';

void main() {
  testWidgets('PetRecommendationLoader renders and animates properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: PetRecommendationLoader(
              size: 130,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PetRecommendationLoader), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 2000));
  });

  testWidgets('PetRecommendationIcon renders properly in icon mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: PetRecommendationIcon(
              size: 38,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PetRecommendationIcon), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });
}
