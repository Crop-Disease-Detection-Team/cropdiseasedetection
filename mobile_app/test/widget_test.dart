
// import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crop_disease_app/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const CropDiseaseApp());
    await tester.pump();
  });
}