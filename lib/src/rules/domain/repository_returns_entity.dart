import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Ensures repository methods return only `*Entity` types, primitives, or
/// nothing. Method parameters are unconstrained — repositories often accept
/// filter/query objects or other value types that don't fit the `Entity`
/// suffix convention.
///
/// Allowed return types:
///   - `void` / no return
///   - primitives: `bool`, `int`, `double`, `num`, `String`, `DateTime`,
///     `Uri`, `Duration`, `dynamic`, `Object`, `Null`
///   - collection/async wrappers whose inner types are allowed:
///     `Future`, `FutureOr`, `Stream`, `List`, `Map`, `Set`, `Iterable`
///   - any type whose name ends with `Entity`
///
/// Anything else (notably `*Model`, random classes) triggers the rule.
/// Models live in the data layer; the repository boundary must convert
/// Models to Entities before returning.
class RepositoryReturnsEntity extends DartLintRule {
  const RepositoryReturnsEntity() : super(code: _code);

  static const _code = LintCode(
    name: 'repository_returns_entity',
    problemMessage:
        'Repository methods must return *Entity types, primitives, or void. Models belong in the data layer.',
  );

  static const _repositoryAnnotations = {
    'Repository',
    'RepositoryImpl',
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
        final isRepository = cls.metadata
            .any((a) => _repositoryAnnotations.contains(a.name.name));
        if (!isRepository) continue;

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
    if (name.endsWith('Entity')) return;

    reporter.atNode(type, _code);
  }
}
