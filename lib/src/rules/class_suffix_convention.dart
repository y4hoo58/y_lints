import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces class-name suffix conventions based on file location.
///
/// Sibling to `required_annotation`: that rule ensures classes carry the
/// right annotation; this one ensures their names carry the right suffix
/// so readers can identify a type's layer at a glance.
///
/// Layer → suffix:
///   - `lib/domain/entities/**`                   → `Entity`
///   - `lib/domain/repositories/**`               → `Repository`
///   - `lib/data/repositories/**`                 → `RepositoryImpl`
///   - `lib/data/models/**_model.dart`            → `Model`
///   - `lib/data/datasources/**`                  → `DataSource`
///   - `lib/presentation/**_cubit.dart`           → `Cubit`
///   - `lib/presentation/**_state.dart`           → `State`
///
/// Private classes (leading `_`) are skipped — they're internal helpers,
/// not layer surface.
class ClassSuffixConvention extends DartLintRule {
  const ClassSuffixConvention() : super(code: _code);

  static const _code = LintCode(
    name: 'class_suffix_convention',
    problemMessage:
        'Class name does not match this layer\'s suffix convention.',
  );

  static final List<_SuffixLayer> _layers = [
    _SuffixLayer(
      suffix: 'Entity',
      matches: (path, file) => path.contains('/lib/domain/entities/'),
    ),
    _SuffixLayer(
      suffix: 'Repository',
      matches: (path, file) => path.contains('/lib/domain/repositories/'),
    ),
    _SuffixLayer(
      suffix: 'RepositoryImpl',
      matches: (path, file) => path.contains('/lib/data/repositories/'),
    ),
    _SuffixLayer(
      suffix: 'Model',
      matches: (path, file) =>
          path.contains('/lib/data/models/') && file.endsWith('_model.dart'),
    ),
    _SuffixLayer(
      suffix: 'DataSource',
      matches: (path, file) => path.contains('/lib/data/datasources/'),
    ),
    _SuffixLayer(
      suffix: 'Cubit',
      matches: (path, file) =>
          path.contains('/lib/presentation/') && file.endsWith('_cubit.dart'),
    ),
    _SuffixLayer(
      suffix: 'State',
      matches: (path, file) =>
          path.contains('/lib/presentation/') && file.endsWith('_state.dart'),
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
        if (name.endsWith(expected.suffix)) continue;
        // Cross-layer escape hatch: a class already named with *some*
        // layer suffix (e.g. ProfileState declared inside a *_cubit.dart
        // file) isn't a naming violation — it's a misplaced-file issue,
        // which is a separate concern.
        if (_anyLayerSuffix(name)) continue;
        // Subclass escape hatch: a class whose direct superclass already
        // ends in a recognized layer suffix is part of a sealed hierarchy
        // (e.g. WalletInitial extends WalletState, ProfileUpdating extends
        // ProfileState). We accept any layer suffix — not just the one
        // this file expects — because misplacement (state classes in a
        // cubit file) is a separate concern, not a naming concern.
        final superName = cls.extendsClause?.superclass.name2.lexeme;
        if (superName != null && _anyLayerSuffix(superName)) continue;
        reporter.atNode(cls, expected.code);
      }
    });
  }
}

bool _anyLayerSuffix(String name) {
  for (final l in ClassSuffixConvention._layers) {
    if (name.endsWith(l.suffix)) return true;
  }
  return false;
}

class _SuffixLayer {
  _SuffixLayer({required this.suffix, required this.matches})
      : code = LintCode(
          name: 'class_suffix_${_snake(suffix)}',
          problemMessage:
              'Public classes in this layer must end with "$suffix".',
        );

  final String suffix;
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
