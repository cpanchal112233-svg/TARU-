import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/measurements/data/measurements_repository.dart';
import 'package:mobile/features/measurements/domain/blood_pressure_measurement.dart';

/// Proves BP fields keep over-length digit input visible and reject save,
/// matching production formatters (digitsOnly, no length truncation).
void main() {
  testWidgets('entering 1234 is not silently truncated and fails validation', (
    WidgetTester tester,
  ) async {
    final TextEditingController systolic = TextEditingController();
    final TextEditingController diastolic = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  key: const Key('systolic'),
                  controller: systolic,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (String? value) {
                    if (!isTechnicallyValidBpMmHgInput(value)) {
                      return 'Enter a valid systolic value.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  key: const Key('diastolic'),
                  controller: diastolic,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (String? value) {
                    if (!isTechnicallyValidBpMmHgInput(value)) {
                      return 'Enter a valid diastolic value.';
                    }
                    return null;
                  },
                ),
                FilledButton(
                  onPressed: () => formKey.currentState?.validate(),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('systolic')), '1234');
    await tester.enterText(find.byKey(const Key('diastolic')), '81');
    await tester.pump();

    expect(systolic.text, '1234');
    expect(diastolic.text, '81');
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Enter a valid systolic value.'), findsOneWidget);
  });

  test(
    'invalid 1234 never creates a blood_pressure measurement document',
    () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      final MeasurementsRepository repository = MeasurementsRepository(
        firestore,
      );
      const String uid = 'bp-input-integrity';

      expect(
        () => repository.recordBloodPressure(
          uid,
          systolicMmHg: 1234,
          diastolicMmHg: 81,
        ),
        throwsArgumentError,
      );

      final snap = await firestore
          .collection('users')
          .doc(uid)
          .collection('measurements')
          .get();
      expect(snap.docs, isEmpty);
    },
  );
}
