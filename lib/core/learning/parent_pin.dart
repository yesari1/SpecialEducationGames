import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

abstract final class ParentPin {
  static bool valid(String pin) => RegExp(r'^[0-9]{4}$').hasMatch(pin);
  static String newSalt() => base64UrlEncode(
    List<int>.generate(16, (_) => Random.secure().nextInt(256)),
  );
  static String hash(String pin, String salt) {
    if (!valid(pin)) throw ArgumentError('four_digits_required');
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  static bool verify(String candidate, String salt, String expected) {
    if (!valid(candidate)) return false;
    final actual = hash(candidate, salt);
    var difference = actual.length ^ expected.length;
    for (var i = 0; i < actual.length; i++) {
      difference |=
          actual.codeUnitAt(i) ^
          (i < expected.length ? expected.codeUnitAt(i) : 0);
    }
    return difference == 0;
  }
}
