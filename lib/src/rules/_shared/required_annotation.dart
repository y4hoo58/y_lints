import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../config/y_lints_config.dart';
import 'y_lints_annotation.dart';

/// Inverse of the per-layer purity rules.
///
/// The purity rules only fire on *annotated* classes — so a class dropped
/// into an architectural folder without its annotation slips past every
/// check. This rule closes that escape hatch: if a file sits in one of the
/// recognised layer locations (and, where relevant, matches the layer's
/// filename convention), it must contain at least one public class carrying
/// the matching annotation.
///
/// Private classes (leading `_`) and files with no class declarations are
/// ignored — the rule is about public layer surface, not helpers or
/// top-level functions/constants.
class RequiredAnnotation extends DartLintRule {
  RequiredAnnotation({YLintsConfig? config})
      : config = config ?? const YLintsConfig(),
        super(code: _code);

  static const _code = LintCode(
    name: 'required_annotation',
    problemMessage:
        'Public classes in this architectural layer must carry the matching annotation.',
  );

  final YLintsConfig config;

  late final List<_Layer> _layers = [
    _Layer(
      annotation: 'DomainEntity',
      matches: (path, file) => path.contains(config.domainEntities),
    ),
    _Layer(
      annotation: 'Repository',
      matches: (path, file) => path.contains(config.domainRepositories),
    ),
    _Layer(
      annotation: 'RepositoryImpl',
      matches: (path, file) => path.contains(config.dataRepositories),
    ),
    _Layer(
      annotation: 'Model',
      matches: (path, file) =>
          path.contains(config.dataModels) && file.endsWith('_model.dart'),
    ),
    _Layer(
      annotation: 'DataSource',
      matches: (path, file) {
        final root = config.dataDatasources;
        final idx = path.indexOf(root);
        if (idx < 0) return false;
        final tail = path.substring(idx + root.length);
        return tail.split('/').length == 2 && file.startsWith('i_');
      },
    ),
    _Layer(
      annotation: 'RemoteDataSource',
      matches: (path, file) =>
          config.datasourceImplementationPath.hasMatch(path) &&
          file.startsWith('remote_'),
    ),
    _Layer(
      annotation: 'MockDataSource',
      matches: (path, file) =>
          config.datasourceImplementationPath.hasMatch(path) &&
          file.startsWith('mock_'),
    ),
    _Layer(
      annotation: 'FeatureCubit',
      matches: (path, file) =>
          config.cubitFilePath.hasMatch(path) && file.endsWith('_cubit.dart'),
    ),
    _Layer(
      annotation: 'FeatureState',
      matches: (path, file) =>
          config.cubitFilePath.hasMatch(path) && file.endsWith('_state.dart'),
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

    _Layer? layer;
    for (final l in _layers) {
      if (l.matches(filePath, fileName)) {
        layer = l;
        break;
      }
    }
    if (layer == null) return;
    final expected = layer;

    context.registry.addCompilationUnit((unit) {
      final publicClasses = unit.declarations
          .whereType<ClassDeclaration>()
          .where((c) => !c.name.lexeme.startsWith('_'))
          .toList();

      if (publicClasses.isEmpty) return;

      final hasMatch = publicClasses.any(
        (c) => hasYLintsAnnotation(c.metadata, {expected.annotation}),
      );
      if (hasMatch) return;

      reporter.atNode(publicClasses.first, expected.code);
    });
  }
}

class _Layer {
  _Layer({required this.annotation, required this.matches})
      : code = LintCode(
          name: 'required_annotation_${_snake(annotation)}',
          problemMessage:
              'Public classes in this layer must be annotated with @$annotation.',
        );

  final String annotation;
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
