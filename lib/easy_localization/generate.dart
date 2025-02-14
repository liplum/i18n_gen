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

String _generateDartFile(Map<String, dynamic> l10nData, GenerateOptions options) {
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
    result.write("const $className();");

    for (final subNode in node.children) {
      if (subNode is ValueNode) {
        result.write('String get ${subNode.key} => "${subNode.keyPath}".tr();');
      } else if (subNode is ObjectNode) {
        result.write("final ${subNode.key} = const ${subNode.buildClassName()}();");
      }
    }

    result.write("}");
  }

  return result.toString();
}

extension on String {
  String toPascalCase() => split('_').map((e) {
        if (e.isEmpty) return '';
        if (e.length == 1) return e.toUpperCase();
        return '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}';
      }).join('');
}

sealed class Node {
  final ObjectNode? parent;
  final List<String> keys;

  Node({
    this.parent,
    required this.keys,
  }) : assert(parent is! ValueNode, 'parent cannot be a ValueNode');

  String get key => keys.last;

  String get keyPath => keys.join(".");

  bool get isRoot => parent == null;

  static Node build(Map<String, dynamic> obj) {
    final root = ObjectNode(keys: const []);
    void process(Map<String, dynamic> currentObj, Node currentNode, List<String> currentKeys) {
      for (final entry in currentObj.entries) {
        final newKeys = [...currentKeys, entry.key];
        if (entry.value is Map<String, dynamic>) {
          final childNode = ObjectNode(parent: currentNode as ObjectNode, keys: newKeys);
          currentNode.asObjectNode.children.add(childNode);
          process(entry.value, childNode as Node, newKeys);
        } else if (entry.value is String) {
          final childNode = ValueNode(parent: currentNode as ObjectNode, keys: newKeys, value: entry.value);
          currentNode.asObjectNode.children.add(childNode);
          currentNode.children.add(ObjectNode(parent: currentNode, keys: newKeys));
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
}

class ValueNode extends Node {
  final String value;

  ValueNode({
    super.parent,
    required super.keys,
    required this.value,
  });
}

class ObjectNode extends Node {
  final children = <Node>[];

  ObjectNode({
    super.parent,
    required super.keys,
  });

  String buildClassName([String prefix = "I18n"]) {
    return "$prefix${keys.map((it) => it.toPascalCase()).join("\$")}";
  }
}

extension _NodeExtension on Node {
  ObjectNode get asObjectNode => this as ObjectNode;

  ValueNode get asValueNode => this as ValueNode;

  bool get isValue => this is ValueNode;
}
