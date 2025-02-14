import 'package:args/args.dart';

abstract class Command {
  String get name;

  ArgParser buildParser();

  Future<void> handle(ArgParser parser, ArgResults results);
}
