enum AppFlavor { staging, production }

class EnvConfig {
  static late final AppFlavor flavor;
  static late final String apiUrl;
  static late final String appName;

  static void init({
    required AppFlavor flavor,
    required String apiUrl,
    required String appName,
  }) {
    EnvConfig.flavor = flavor;
    EnvConfig.apiUrl = apiUrl;
    EnvConfig.appName = appName;
  }
}
