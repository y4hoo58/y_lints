import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Shared path configuration for y_lints.
///
/// Read from `analysis_options.yaml` via a pseudo-rule block:
///
/// ```yaml
/// custom_lint:
///   rules:
///     - y_lints:
///         root: lib/
///         domain: domain/
///         data: data/
///         presentation: presentation/
/// ```
///
/// All four fields are optional; defaults mirror the clean-architecture
/// layout the package is built around. Intra-layer folder names
/// (`entities/`, `repositories/`, `models/`, `datasources/`, `cubits/`,
/// `view/`) remain fixed — this config only moves the layer roots.
class YLintsConfig {
  const YLintsConfig({
    this.root = 'lib/',
    this.domain = 'domain/',
    this.data = 'data/',
    this.presentation = 'presentation/',
  });

  /// Parse from a custom_lint `CustomLintConfigs`. Missing/invalid keys
  /// fall back to defaults.
  factory YLintsConfig.fromLintConfigs(CustomLintConfigs configs) {
    final json = configs.rules['y_lints']?.json ?? const <String, Object?>{};
    return YLintsConfig(
      root: _trailingSlash(_stringOr(json['root'], 'lib/')),
      domain: _trailingSlash(_stringOr(json['domain'], 'domain/')),
      data: _trailingSlash(_stringOr(json['data'], 'data/')),
      presentation:
          _trailingSlash(_stringOr(json['presentation'], 'presentation/')),
    );
  }

  final String root;
  final String domain;
  final String data;
  final String presentation;

  String get _domainBase => '/$root$domain';
  String get _dataBase => '/$root$data';
  String get _presentationBase => '/$root$presentation';

  String get domainEntities => '${_domainBase}entities/';
  String get domainRepositories => '${_domainBase}repositories/';
  String get dataRepositories => '${_dataBase}repositories/';
  String get dataModels => '${_dataBase}models/';
  String get dataDatasources => '${_dataBase}datasources/';
  String get presentation_ => _presentationBase;

  /// Regex for a file directly under `data/datasources/<feature>/` (not
  /// inside implementations/). Matches the `i_*.dart` contract location.
  RegExp get datasourceContractFilePath =>
      RegExp('${_escape(dataDatasources)}[^/]+/[^/]+\\.dart\$');

  /// Regex for `data/datasources/<feature>/implementations/*.dart`.
  RegExp get datasourceImplementationPath => RegExp(
      '${_escape(dataDatasources)}[^/]+/implementations/[^/]+\\.dart\$');

  /// Regex for `presentation/<feature>/cubits/<cubit_name>/*.dart`.
  RegExp get cubitFilePath => RegExp(
      '${_escape(_presentationBase)}[^/]+/cubits/[^/]+/[^/]+\\.dart\$');

  /// Regex for `presentation/<feature>/view/*.dart`.
  RegExp get featureViewPath =>
      RegExp('${_escape(_presentationBase)}[^/]+/view/[^/]+\\.dart\$');
}

String _stringOr(Object? value, String fallback) =>
    value is String && value.isNotEmpty ? value : fallback;

String _trailingSlash(String s) => s.endsWith('/') ? s : '$s/';

String _escape(String s) => s.replaceAllMapped(
      RegExp(r'[.*+?^${}()|[\]\\]'),
      (m) => '\\${m[0]}',
    );
