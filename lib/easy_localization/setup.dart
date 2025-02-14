import 'dart:io';

import 'package:args/args.dart';
import 'package:i18n_gen/command.dart';
import 'package:i18n_gen/easy_localization/generate.dart';
import 'package:i18n_gen/utils.dart';
import 'package:path/path.dart' as path;

class EasyLocalizationCommand implements Command {
  const EasyLocalizationCommand();

  @override
  String get name => "easy_localization";

  @override
  ArgParser buildParser() {
    final parser = ArgParser();
    parser
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Print this usage information.',
      )
      ..addFlag(
        'version',
        negatable: false,
        help: 'Print the tool version.',
      );

    parser.addOption(
      'source-dir',
      abbr: 's',
      help: 'The folder containing localization files',
    );

    parser.addOption(
      'output-file',
      abbr: 'o',
      help: 'The output file path',
    );

    parser.addOption(
      'source-file-type',
      abbr: 't',
      help: 'The file type of source localization files',
    );
    return parser;
  }

  @override
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
}
