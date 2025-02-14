import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

enum ProjectFileType {
  json(extensions: [".json"]),
  yaml(extensions: [".yaml", ".yml"]),
  ;

  final List<String> extensions;

  const ProjectFileType({
    required this.extensions,
  });

  static ProjectFileType? tryParseExtension(String ext) {
    for (final type in values) {
      if (type.extensions.contains(ext)) {
        return type;
      }
    }
    return null;
  }

  static Future<ProjectFileType?> estimateFromFiles(List<String> files) async {
    final ext2Count = files.groupFoldBy<String, int>((it) => path.extension(it), (pre, next) => (pre ?? 0) + 1);
    final ascendingByCount = ext2Count.entries.sortedBy<num>((it) => it.value);
    final mostCommonExt = ascendingByCount.lastOrNull;
    if (mostCommonExt == null) return null;
    return ProjectFileType.tryParseExtension(mostCommonExt.key);
  }
}
