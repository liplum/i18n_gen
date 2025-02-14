import 'package:args/args.dart';
import 'package:i18n_gen/easy_localization/setup.dart';

const String version = '0.0.1';

const commands = [
  EasyLocalizationCommand(),
];

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
  return parser;
}

void printUsage(ArgParser argParser) {
  print('Usage: dart i18n_gen.dart <command> [arguments]');
  print(argParser.usage);
}

Future<void> main(List<String> arguments) async {
  final parser = buildParser();
  final command2Parser = <String, ArgParser>{};
  for (final command in commands) {
    final commandParser = command.buildParser();
    parser.addCommand(command.name, commandParser);
    command2Parser[command.name] = commandParser;
  }
  try {
    final results = parser.parse(arguments);
    // Process the parsed arguments.
    if (results.flag('help')) {
      printUsage(parser);
      return;
    }
    if (results.flag('version')) {
      print('i18n_gen version: $version');
      return;
    }
    final command = results.command;
    if (command != null) {
      final matched = commands.firstWhere((cmd) => cmd.name == command.name);
      await matched.handle(
        command2Parser[command.name]!,
        command,
      );
    }
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
    print(e.message);
    print('');
    printUsage(parser);
  }
}
