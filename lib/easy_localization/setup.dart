import 'package:args/args.dart';
import 'package:i18n_gen/command.dart';

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
    return parser;
  }

  @override
  void handle(ArgParser parser,ArgResults results) {
    if (results.flag('help')) {
      print(parser.usage);
      return;
    }
  }
}
