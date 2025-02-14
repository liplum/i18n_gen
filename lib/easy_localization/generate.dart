import 'dart:async';
import 'dart:convert';
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



  return result.toString();
}

Future _writeJson(StringBuffer classBuilder, List<FileSystemEntity> files) async {
  var gFile = '''
// DO NOT EDIT. This is code generated via package:easy_localization/generate.dart

// ignore_for_file: prefer_single_quotes, avoid_renaming_method_parameters, constant_identifier_names

import 'dart:ui';

import 'package:easy_localization/easy_localization.dart' show AssetLoader;

class CodegenLoader extends AssetLoader{
  const CodegenLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    return Future.value(mapLocales[locale.toString()]);
  }

  ''';

  final listLocales = [];

  for (var file in files) {
    final localeName = path.basename(file.path).replaceFirst('.json', '').replaceAll('-', '_');
    listLocales.add('"$localeName": _$localeName');
    final fileData = File(file.path);

    Map<String, dynamic>? data = json.decode(await fileData.readAsString());

    final mapString = const JsonEncoder.withIndent('  ').convert(data);
    gFile += 'static const Map<String,dynamic> _$localeName = $mapString;\n';
  }

  gFile += 'static const Map<String, Map<String,dynamic>> mapLocales = {${listLocales.join(', ')}};';
  classBuilder.writeln(gFile);
}
