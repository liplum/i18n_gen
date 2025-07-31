import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:i18n_gen/easy_localization/generate.dart';
import 'package:i18n_gen/utils.dart';
import 'package:path/path.dart' as path;

class EasyLocalizationCommand extends Command {
  EasyLocalizationCommand() {
    argParser.addOption(
      'source-dir',
      abbr: 's',
      help: 'The folder containing localization files',
    );

    argParser.addOption(
      'output-file',
      abbr: 'o',
      help: 'The output file path',
    );

    argParser.addOption(
      'source-file-type',
      abbr: 't',
      help: 'The file type of source localization files',
    );
  }

  @override
  String get name => "easy_localization";

  @override
  String get description => "Generate dart files from localization files in easy_localization format.";

  Future<void> handle(ArgParser parser, ArgResults results) async {
    if (results.flag('help')) {
      print(parser.usage);
      return;
    }
    var sourceDir = results.option("source-dir");
    var outputFile = results.option("output-file");
    final cwd = Directory.current;
    final pubspec = findPubspecPath(cwd);
    if (pubspec == null) {
      if (sourceDir == null || outputFile == null) {
        throw Exception("No source-dir or output-file given.");
      }
    } else {
      final projectRoot = File(pubspec).parent;
      sourceDir ??= File(path.join(projectRoot.path, "assets/translations")).path;
      outputFile ??= File(path.join(projectRoot.path, "lib/generated/l10n.dart")).path;
    }

    final options = GenerateOptions(
      outputFile: outputFile,
      sourceDir: sourceDir,
    );
    await generate(options);
  }

  @override
  Future<void> run() async {
    final argResults = this.argResults;
    if (argResults == null) return;
    var sourceDir = argResults.option("source-dir");
    var outputFile = argResults.option("output-file");
    final cwd = Directory.current;
    final pubspec = findPubspecPath(cwd);
    if (pubspec == null) {
      if (sourceDir == null || outputFile == null) {
        throw Exception("No source-dir or output-file given.");
      }
    } else {
      final projectRoot = File(pubspec).parent;
      sourceDir ??= File(path.join(projectRoot.path, "assets/translations")).path;
      outputFile ??= File(path.join(projectRoot.path, "lib/generated/l10n.dart")).path;
    }

    final options = GenerateOptions(
      outputFile: outputFile,
      sourceDir: sourceDir,
    );
    await generate(options);
  }
}
