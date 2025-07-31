import 'package:args/command_runner.dart';
import 'package:i18n_gen/easy_localization/setup.dart';

const String version = '0.0.1';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner("i18n_gen", "Generate dart files from localization files. v$version.")
    ..addCommand(EasyLocalizationCommand());
  runner.run(arguments);
}
