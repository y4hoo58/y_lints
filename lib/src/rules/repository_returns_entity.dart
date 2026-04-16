import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Ensures repository classes expose only `*Entity` types, primitives, or
/// nothing in their method signatures (return types and parameters).
///
/// Allowed types:
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
        'Repository method signatures must use *Entity types, primitives, or void. Models belong in the data layer.',
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
          for (final param in member.parameters?.parameters ??
              const <FormalParameter>[]) {
            _checkType(_typeOf(param), reporter);
          }
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

  TypeAnnotation? _typeOf(FormalParameter p) {
    if (p is DefaultFormalParameter) return _typeOf(p.parameter);
    if (p is SimpleFormalParameter) return p.type;
    if (p is FieldFormalParameter) return p.type;
    return null;
  }
}
