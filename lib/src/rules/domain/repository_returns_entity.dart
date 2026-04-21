import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../_shared/boundary_type.dart';
import '../_shared/y_lints_annotation.dart';

/// Ensures repository method signatures only expose domain-safe types.
///
/// Classification runs against the resolved type element, not the name:
///   - `void`, primitives (`bool`, `int`, `double`, `num`, `String`),
///     `dart:core` value types (`DateTime`, `Duration`, `Uri`), `dynamic`,
///     `Null`, `Object`
///   - async / collection wrappers (`Future`, `FutureOr`, `Stream`, `List`,
///     `Map`, `Set`, `Iterable`) whose inner types are themselves allowed
///   - any enum
///   - unresolved type parameters
///   - any class carrying `@DomainEntity`
///
/// Anything else — notably `*Model` DTOs, or entity-suffixed classes that
/// never declared `@DomainEntity` — triggers the rule. Models live in the
/// data layer; the repository boundary must convert them to entities before
/// handing them to callers.
class RepositoryReturnsEntity extends DartLintRule {
  const RepositoryReturnsEntity() : super(code: _code);

  static const _code = LintCode(
    name: 'repository_returns_entity',
    problemMessage:
        'Repository method signatures must use @DomainEntity types, enums, primitives, or void. Models belong in the data layer.',
  );

  static const _repositoryAnnotations = {
    'Repository',
    'RepositoryImpl',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      for (final cls in unit.declarations.whereType<ClassDeclaration>()) {
        if (!hasYLintsAnnotation(cls.metadata, _repositoryAnnotations)) {
          continue;
        }

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

  void _checkType(TypeAnnotation? annotation, ErrorReporter reporter) {
    if (annotation is! NamedType) return;
    final allowed = isAllowedBoundaryType(
      annotation.type,
      markerAnnotations: const {'DomainEntity'},
    );
    if (!allowed) reporter.atNode(annotation, _code);
  }

  TypeAnnotation? _typeOf(FormalParameter p) {
    if (p is DefaultFormalParameter) return _typeOf(p.parameter);
    if (p is SimpleFormalParameter) return p.type;
    if (p is FieldFormalParameter) return p.type;
    return null;
  }
}
