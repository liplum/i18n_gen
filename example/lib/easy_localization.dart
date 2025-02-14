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
  final app = const I18n$app();
  final index = const I18n$index();
}

class I18n$app {
  const I18n$app();

  String get name => "app.i18n_gen".tr();

  String get author => "app.author".tr();
}

class I18n$index {
  const I18n$index();

  String get title => "index.title".tr();

  String get desc => "index.desc".tr();
}

class I18n$home {
  const I18n$home();

  String get title => "home.title".tr();

  String get desc => "home.desc".tr();
}

class I18n$home$settings {
  const I18n$home$settings();

  String get title => "home.settings.title".tr();
}

class I18n$home$settings$showButton {
  const I18n$home$settings$showButton();

  String get title => "home.settings.showButton.title".tr();

  String get desc => "home.settings.showButton.desc".tr();
}
