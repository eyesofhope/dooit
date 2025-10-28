import 'dart:async';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return GoldenToolkit.runWithConfiguration(
    () async {
      await loadAppFonts();
      await testMain();
    },
    config: GoldenToolkitConfiguration(
      skipGoldenAssertion: () => false,
      defaultDevices: const [
        Device(name: 'phone', size: Size(375, 667)),
        Device(name: 'tablet', size: Size(768, 1024)),
      ],
    ),
  );
}
