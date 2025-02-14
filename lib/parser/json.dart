import 'dart:convert';

import 'parser.dart';

class L10nParserJson implements L10nParser {
  const L10nParserJson();

  @override
  Map<dynamic, dynamic> parseNestedObject(String content) {
    final obj = jsonDecode(content);
    return obj;
  }
//
// Map<String, String> parseFlattenObject(String content) {
//   final obj = jsonDecode(content);
//
// }
}
