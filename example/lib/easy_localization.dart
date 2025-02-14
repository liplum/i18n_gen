// ignore_for_file: type=lint

import 'package:easy_localization/easy_localization.dart';

final exampleYaml = """
topLevel: Top-level values
app:
  name: i18n_gen
  author: Liplum
index:
  title: Index page
  desc: This is the index page
home:
  title: Homepage
  desc: This is the homepage
  settings:
    title: Settings
    showButton:
      title: Show the button
      desc: Show the button on the homepage
""";

class I18n {
  String get topLevel => "topLevel".tr();
  final app = const I18n$app._("app");
  final index = const I18n$index._("app");
}

class I18n$app {
  final String ns;

  const I18n$app._(this.ns);

  String get name => "$ns.i18n_gen".tr();

  String get author => "$ns.author".tr();
}

class I18n$index {
  final String ns;

  const I18n$index._(this.ns);

  String get title => "$ns.title".tr();

  String get desc => "$ns.desc".tr();
}

class I18n$home {
  final String ns;

  const I18n$home._(this.ns);

  String get title => "$ns.title".tr();

  String get desc => "$ns.desc".tr();
}

class I18n$home$settings {
  final String ns;

  const I18n$home$settings._(this.ns);

  String get title => "$ns.title".tr();
}

class I18n$home$settings$showButton {
  final String ns;

  const I18n$home$settings$showButton._(this.ns);

  String get title => "$ns.title".tr();

  String get desc => "$ns.desc".tr();
}
