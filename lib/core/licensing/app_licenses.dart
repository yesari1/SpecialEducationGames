import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Registers licenses for application assets that are not included in
/// Flutter's generated dependency notices.
class AppLicenses {
  AppLicenses._();

  static bool _nunitoRegistered = false;

  /// Adds Nunito's bundled OFL text to the in-app open-source license list.
  ///
  /// The asset is loaded only when the license registry is read, and repeated
  /// calls do not add duplicate entries.
  static void registerNunito() {
    if (_nunitoRegistered) return;
    _nunitoRegistered = true;
    LicenseRegistry.addLicense(_nunitoLicense);
  }

  static Stream<LicenseEntry> _nunitoLicense() async* {
    final licenseText = await rootBundle.loadString('assets/fonts/OFL.txt');
    if (licenseText.isEmpty) {
      throw StateError('The bundled Nunito OFL license is empty.');
    }
    yield LicenseEntryWithLineBreaks(const ['Nunito'], licenseText);
  }
}
