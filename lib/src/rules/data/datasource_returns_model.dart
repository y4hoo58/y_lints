import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Ensures datasource methods return only `*Model` types, primitives, or
/// nothing. Method parameters are unconstrained — request DTOs, query
/// objects, and auth tokens often don't carry the `Model` suffix.
///
/// Allowed return types:
///   - `void` / no return
///   - primitives: `bool`, `int`, `double`, `num`, `String`, `DateTime`,
///     `Uri`, `Duration`, `dynamic`, `Object`, `Null`
///   - collection/async wrappers whose inner types are allowed:
///     `Future`, `FutureOr`, `Stream`, `List`, `Map`, `Set`, `Iterable`
///   - any type whose name ends with `Model`
///
/// Anything else (notably `*Entity`, feature-specific DTO-less types,
/// random classes) triggers the rule. The DTO boundary must live at the
/// datasource — entities only appear once repositories convert them.
class DatasourceReturnsModel extends DartLintRule {
  const DatasourceReturnsModel() : super(code: _code);

  static const _code = LintCode(
    name: 'datasource_returns_model',
    problemMessage:
        'Datasource methods must return *Model types, primitives, or void. Convert to Entity inside the repository.',
  );

  static const _datasourceAnnotations = {
    'DataSource',
    'RemoteDataSource',
    'MockDataSource',
  };

  static const _allowedTypeNames = {
    'void',
    'bool',
    'int',
    'double',
    'num',
    'String',
    'DateTime',
    'Uri',
    'Duration',
    'dynamic',
    'Object',
    'Null',
  };

  static const _wrapperTypeNames = {
    'Future',
    'FutureOr',
    'Stream',
    'List',
    'Map',
    'Set',
    'Iterable',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      for (final cls in unit.declarations.whereType<ClassDeclaration>()) {
        final isDatasource = cls.metadata
            .any((a) => _datasourceAnnotations.contains(a.name.name));
        if (!isDatasource) continue;

        for (final member in cls.members.whereType<MethodDeclaration>()) {
          _checkType(member.returnType, reporter);
        }
      }
    });
  }

  void _checkType(TypeAnnotation? type, ErrorReporter reporter) {
    if (type is! NamedType) return;
    final name = type.name2.lexeme;
    final args = type.typeArguments?.arguments ?? const <TypeAnnotation>[];

    if (_wrapperTypeNames.contains(name)) {
      for (final arg in args) {
        _checkType(arg, reporter);
      }
      return;
    }
    if (_allowedTypeNames.contains(name)) return;
    if (name.endsWith('Model')) return;

    reporter.atNode(type, _code);
  }
}
