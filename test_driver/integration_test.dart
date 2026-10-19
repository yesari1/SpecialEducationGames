import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      const pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];
      if (bytes.length < pngSignature.length ||
          List<int>.generate(
                pngSignature.length,
                (index) => bytes[index],
              ).toString() !=
              pngSignature.toString()) {
        return false;
      }
      final file = File('artifacts/screenshots/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return await file.length() == bytes.length;
    },
  );
}
