import 'package:yaml/yaml.dart';

import 'parser.dart';

class L10nParserYaml implements L10nParser {
  const L10nParserYaml();

  @override
  Map<String, dynamic> parseNestedObject(String content) {
    final obj = loadYaml(content);
    return obj;
  }
}
