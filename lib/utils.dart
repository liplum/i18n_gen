import 'dart:io';
import 'package:path/path.dart' as path;

String? findPubspecPath(Directory starting) {
  var current = starting;
  while (current.path != current.parent.path) {
    final pubspec = File(path.join(current.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      return pubspec.path;
    }
    current = current.parent;
  }
  return null; // Not found
}
