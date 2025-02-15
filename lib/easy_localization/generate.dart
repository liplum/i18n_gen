import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:i18n_gen/parser/json.dart';
import 'package:i18n_gen/parser/yaml.dart';
import 'package:i18n_gen/project.dart';
import 'package:path/path.dart' as path;

class GenerateOptions {
  final String sourceDir;
  final String outputFile;
  final ProjectFileType? projectFileType;

  const GenerateOptions({
    required this.sourceDir,
    required this.outputFile,
    this.projectFileType,
  });
}

Future<void> generate(GenerateOptions options) async {
  final sourceDir = Directory(options.sourceDir);
  final outputPath = Directory(options.outputFile);

  if (!sourceDir.existsSync()) {
    stderr.writeln('Source dir does not exist');
    return;
  }

  final files = (await sourceDir.list().toList()).whereType<File>();
  final type = options.projectFileType ??
      await ProjectFileType.estimateFromFiles(files.map((it) => it.path).toList()) ??
      ProjectFileType.json;
  final parser = switch (type) {
    ProjectFileType.json => const L10nParserJson(),
    ProjectFileType.yaml => const L10nParserYaml(),
  };
  final file =
      files.firstWhereOrNull((it) => path.basenameWithoutExtension(it.path).contains("en")) ?? files.firstOrNull;
  if (file == null || !file.existsSync()) {
    stderr.writeln('No source file found');
    return;
  }
  final l10nData = parser.parseNestedObject(await file.readAsString());
  final result = _generateDartFile(l10nData, options);
  final generatedFile = File(outputPath.path);
  await generatedFile.writeAsString(result);
}

const _preservedKeywords = [
  'few',
  'many',
  'one',
  'other',
  'two',
  'zero',
  'male',
  'female',
];

String _generateDartFile(Map<dynamic, dynamic> l10nData, GenerateOptions options) {
  final result = StringBuffer();

  result.write('''
// ignore_for_file: type=lint
import "package:easy_localization/easy_localization.dart";

''');

  final rootNode = Node.build(l10nData);
  final allObjectNodes = rootNode.listAllObjectNodes();

  for (final node in allObjectNodes) {
    final className = node.buildClassName();
    result.write(
      "class $className {\n",
    );
    result.write("  const $className();\n");

    final subObjectNodes = node.children.whereType<ObjectNode>();

    if (subObjectNodes.isNotEmpty) {
      result.write("\n");
    }
    for (final subNode in subObjectNodes) {
      result.write('  ${subNode.buildStatement()};\n');
    }
    final subValueNodes = node.children.whereType<ValueNode>().toList();
    if (subValueNodes.isNotEmpty) {
      result.write("\n");
    }

    for (var i = 0; i < subValueNodes.length; ++i) {
      final subNode = subValueNodes[i];
      result.write('  ${subNode.buildStatement()};\n');
      if (i < subValueNodes.length - 1) {
        result.write("\n");
      }
    }
    result.write("}\n");
    result.write("\n");
  }

  return result.toString();
}

const _dartKeywords = {
  "abstract",
  "as",
  "assert",
  "async",
  "await",
  "break",
  "case",
  "catch",
  "class",
  "const",
  "continue",
  "covariant",
  "default",
  "deferred",
  "do",
  "dynamic",
  "else",
  "enum",
  "extends",
  "extension",
  "external",
  "factory",
  "false",
  "final",
  "finally",
  "for",
  "Function",
  "get",
  "hide",
  "if",
  "implements",
  "import",
  "in",
};

extension on String {
  bool isValidVariableName() {
    if (_dartKeywords.contains(this)) return false;
    if (int.tryParse(this) != null) return false;
    if (double.tryParse(this) != null) return false;
    return true;
  }

  String toPascalCase() {
    final parts = split(RegExp(r'[-_]'));
    final capitalized = parts.map((part) {
      if (part.isEmpty) return '';
      return part
          .split('')
          .mapIndexed((index, char) => switch (index) {
                0 => char.toUpperCase(),
                _ => !char.isUpperCase ? char.toLowerCase() : char,
              })
          .join();
    });

    return capitalized.join('');
  }

  String toCamelCase() {
    if (isEmpty) return '';
    final pascalCase = toPascalCase();
    if (pascalCase.length == 1) {
      return pascalCase.toLowerCase();
    } else {
      return '${pascalCase[0].toLowerCase()}${pascalCase.substring(1)}';
    }
  }

  bool get isUpperCase {
    return toUpperCase() == this;
  }
}

sealed class Node {
  final ObjectNode? parent;
  final List<String> keys;

  Node({
    this.parent,
    required this.keys,
  }) : assert(parent is! ValueNode, 'parent cannot be a ValueNode');

  String get key => keys.last;

  String toVariableName() {
    final result = key.toCamelCase();
    if (!result.isValidVariableName()) return "\$$result";
    return result;
  }

  String get keyPath => keys.join(".");

  bool get isRoot => parent == null;

  static Node build(Map<dynamic, dynamic> obj) {
    final root = ObjectNode(keys: const []);
    void process(Map<dynamic, dynamic> currentObj, ObjectNode currentNode, List<String> currentKeys) {
      for (final entry in currentObj.entries) {
        final newKeys = [...currentKeys, "${entry.key}"];
        if (entry.value is Map) {
          final childNode = ObjectNode(parent: currentNode, keys: newKeys);
          currentNode.children.add(childNode);
          process(entry.value, childNode, newKeys);
        } else if (entry.value is String) {
          final childNode = ValueNode.create(
            parent: currentNode,
            keys: newKeys,
            value: entry.value,
          );
          currentNode.children.add(childNode);
        }
      }
    }

    process(obj, root, const []);
    return root;
  }

  List<Node> listAllNodes() {
    final result = <Node>[];
    void process(Node node) {
      result.add(node);
      if (node is ObjectNode) {
        node.children.forEach(process);
      }
    }

    process(this);
    return result;
  }

  List<ObjectNode> listAllObjectNodes() {
    final result = <ObjectNode>[];
    void process(Node node) {
      if (node is ObjectNode) {
        result.add(node);
        node.children.forEach(process);
      }
    }

    process(this);
    return result;
  }

  String buildStatement();

  @override
  String toString() => keyPath;
}

class ValueNode extends Node {
  final String value;

  /// example:
  /// - `My name is {}.`
  /// - `I'm { }.`
  ///
  /// Whitespaces between brackets are allowed.
  final int positionalArgs;

  /// example:
  /// - `My name is {name}.`
  /// - `I'm {year} years old.`
  ///
  /// Whitespace between brackets are allowed.
  final List<String> namedArgs;

  ValueNode({
    super.parent,
    required super.keys,
    required this.value,
    required this.positionalArgs,
    required this.namedArgs,
  });

  factory ValueNode.create({
    ObjectNode? parent,
    required List<String> keys,
    required String value,
  }) {
    final allArgs = _extractArgs(value);
    final positionalArgs = allArgs.where((it) => it.name == null).length;
    final namedArgs = allArgs.where((it) => it.name != null).map((e) => e.name!).toList();

    return ValueNode(
      keys: keys,
      value: value,
      positionalArgs: positionalArgs,
      namedArgs: namedArgs,
    );
  }

  @override
  String buildStatement() {
    if (namedArgs.isEmpty && positionalArgs == 0) {
      return 'String get ${toVariableName()} => r"$keyPath".tr();';
    }
    return 'String ${toVariableName()}() => r"$keyPath".tr();';
  }
}

class _ParsedArg {
  final String? name;

  const _ParsedArg(this.name);
}

List<_ParsedArg> _extractArgs(String value) {
  final regExp = RegExp(r'\{([\w\s]*?)\}');
  final matches = regExp.allMatches(value);
  final result = <_ParsedArg>[];
  for (final match in matches) {
    final captureGroup = match.group(1);
    if (captureGroup != null) {
      final trimmed = captureGroup.trim();
      final isNamed = trimmed.isNotEmpty;
      result.add(_ParsedArg(isNamed ? trimmed : null));
    }
  }
  return result;
}

class ObjectNode extends Node {
  final children = <Node>[];

  ObjectNode({
    super.parent,
    required super.keys,
  });

  String buildClassName([String prefix = "I18n"]) {
    if (keys.isEmpty) return prefix;
    return "$prefix\$${keys.map((it) => it.toPascalCase()).join("\$")}";
  }

  @override
  String buildStatement() {
    return 'final ${toVariableName()} = const ${buildClassName()}();';
  }
}
