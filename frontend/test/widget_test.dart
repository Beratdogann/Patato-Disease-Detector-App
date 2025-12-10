// Basic Flutter widget test for Potato Disease Detector
//
// This test verifies that the app renders correctly.

import 'package:flutter_test/flutter_test.dart';

import 'package:potato_disease_detector/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PotatoDiseaseDetectorApp());

    // Verify that the title is displayed.
    expect(find.text('Potato Disease Detector'), findsOneWidget);
    
    // Verify that the subtitle is displayed.
    expect(find.textContaining('Upload a potato leaf'), findsOneWidget);
    
    // Verify that the buttons are displayed.
    expect(find.text('Select Image'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Analyze'), findsOneWidget);
  });
}
