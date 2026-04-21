import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../config/y_lints_config.dart';
import 'y_lints_annotation.dart';

/// Enforces class-name suffix conventions based on file location.
///
/// Sibling to `required_annotation`: that rule ensures classes carry the
/// right annotation; this one ensures their names carry the right suffix
/// so readers can identify a type's layer at a glance.
///
/// Layer → suffix:
///   - `domain/entities/**`                   → `Entity`
///   - `domain/repositories/**`               → `Repository`
///   - `data/repositories/**`                 → `RepositoryImpl`
///   - `data/models/**_model.dart`            → `Model`
///   - `data/datasources/**`                  → `DataSource` (or `Datasource`)
///   - `presentation/**_cubit.dart`           → `Cubit`
///   - `presentation/**_state.dart`           → `State`
///
/// Layer path prefixes are derived from the project's `YLintsConfig`.
///
/// Private classes (leading `_`) are skipped — they're internal helpers,
/// not layer surface.
class ClassSuffixConvention extends DartLintRule {
  ClassSuffixConvention({YLintsConfig? config})
      : config = config ?? const YLintsConfig(),
        super(code: _code);

  static const _code = LintCode(
    name: 'class_suffix_convention',
    problemMessage:
        'Class name does not match this layer\'s suffix convention.',
  );

  final YLintsConfig config;

  late final List<_SuffixLayer> _layers = [
    _SuffixLayer(
      suffix: 'Entity',
      matches: (path, file) => path.contains(config.domainEntities),
    ),
    _SuffixLayer(
      suffix: 'Repository',
      matches: (path, file) => path.contains(config.domainRepositories),
    ),
    _SuffixLayer(
      suffix: 'RepositoryImpl',
      matches: (path, file) => path.contains(config.dataRepositories),
    ),
    _SuffixLayer(
      suffix: 'Model',
      matches: (path, file) =>
          path.contains(config.dataModels) && file.endsWith('_model.dart'),
    ),
    _SuffixLayer(
      suffix: 'DataSource',
      alternates: ['Datasource'],
      matches: (path, file) => path.contains(config.dataDatasources),
    ),
    _SuffixLayer(
      suffix: 'Cubit',
      matches: (path, file) =>
          path.contains(config.presentation_) && file.endsWith('_cubit.dart'),
    ),
    _SuffixLayer(
      suffix: 'State',
      matches: (path, file) =>
          path.contains(config.presentation_) && file.endsWith('_state.dart'),
    ),
  ];

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.source.fullName;
    final fileName = filePath.split(RegExp(r'[/\\]')).last;

    _SuffixLayer? layer;
    for (final l in _layers) {
      if (l.matches(filePath, fileName)) {
        layer = l;
        break;
      }
    }
    if (layer == null) return;
    final expected = layer;

    context.registry.addCompilationUnit((unit) {
      for (final cls in unit.declarations.whereType<ClassDeclaration>()) {
        final name = cls.name.lexeme;
        if (name.startsWith('_')) continue;
        if (expected.accepts.any(name.endsWith)) continue;
        // Cross-layer escape hatch: a class already named with *some*
        // layer suffix (e.g. ProfileState declared inside a *_cubit.dart
        // file) isn't a naming violation — it's a misplaced-file issue,
        // which is a separate concern.
        if (_anyLayerSuffix(name)) continue;
        // Subclass escape hatch: a class whose direct superclass already
        // carries a y_lints architectural annotation is part of a sealed
        // hierarchy (e.g. WalletInitial extends WalletState, where
        // WalletState is `@FeatureState`). Any layer annotation counts —
        // not just the one this file expects — because misplacement
        // (state classes in a cubit file) is a separate concern.
        final superclass = cls.extendsClause?.superclass;
        if (superclass != null && _superHasLayerAnnotation(superclass)) {
          continue;
        }
        reporter.atNode(cls, expected.code);
      }
    });
  }

  bool _anyLayerSuffix(String name) {
    for (final l in _layers) {
      if (l.accepts.any(name.endsWith)) return true;
    }
    return false;
  }
}

const _layerAnnotations = {
  'DomainEntity',
  'Repository',
  'RepositoryImpl',
  'Model',
  'DataSource',
  'RemoteDataSource',
  'MockDataSource',
  'FeatureCubit',
  'FeatureState',
  'FeatureBuilder',
  'Page',
};

bool _superHasLayerAnnotation(NamedType superclass) {
  final element = superclass.element2;
  if (element is! InterfaceElement2) return false;
  return elementHasYLintsAnnotation(element, _layerAnnotations);
}

class _SuffixLayer {
  _SuffixLayer({
    required this.suffix,
    required this.matches,
    List<String> alternates = const [],
  })  : accepts = [suffix, ...alternates],
        code = LintCode(
          name: 'class_suffix_${_snake(suffix)}',
          problemMessage: alternates.isEmpty
              ? 'Public classes in this layer must end with "$suffix".'
              : 'Public classes in this layer must end with "$suffix" (or ${alternates.map((a) => '"$a"').join(', ')}).',
        );

  final String suffix;
  final List<String> accepts;
  final bool Function(String path, String file) matches;
  final LintCode code;
}

String _snake(String camel) {
  final out = StringBuffer();
  for (var i = 0; i < camel.length; i++) {
    final c = camel[i];
    final lower = c.toLowerCase();
    if (i > 0 && c != lower) out.write('_');
    out.write(lower);
  }
  return out.toString();
}
