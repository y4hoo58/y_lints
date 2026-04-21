import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../_shared/boundary_type.dart';
import '../_shared/y_lints_annotation.dart';

/// Restricts what a `@FeatureCubit` constructor is allowed to depend on.
///
/// Cubits are presentation orchestrators. They should talk to the domain
/// through repository contracts — nothing else. This rule inspects every
/// constructor parameter on a `@FeatureCubit` class and accepts only:
///
///   - `void`, primitives (`bool`, `int`, `double`, `num`, `String`),
///     `dart:core` value types (`DateTime`, `Duration`, `Uri`), `dynamic`,
///     `Null`, `Object`
///   - async / collection wrappers (`Future`, `FutureOr`, `Stream`, `List`,
///     `Map`, `Set`, `Iterable`) whose inner types are themselves allowed
///   - any enum
///   - any class carrying `@Repository` (domain contract)
///   - any class carrying `@DomainEntity` (initial/seed domain data)
///
/// Classification runs against the resolved element, not the name.
/// A class called `FooRepository` that never declared `@Repository` does
/// *not* pass — which is the point: infrastructure can masquerade with the
/// right suffix, but it cannot fake the annotation.
///
/// Resolution covers:
///   - `FooCubit(AuthRepository repo)` (plain parameter)
///   - `FooCubit({required AuthRepository repo})` (named/optional)
///   - `FooCubit(this._authRepository)` (field-initialising; looks up the
///     field's declared type when the parameter itself has no annotation)
///
/// `super.x` and function-typed parameters are skipped.
class CubitConstructorDependencies extends DartLintRule {
  const CubitConstructorDependencies() : super(code: _code);

  static const _code = LintCode(
    name: 'cubit_constructor_dependencies',
    problemMessage:
        '@FeatureCubit constructors may only depend on @Repository contracts, @DomainEntity types, enums, or primitives. Inject a repository, not a *Impl, *DataSource, Dio, or other infrastructure.',
  );

  static const _allowed = {'Repository', 'DomainEntity'};

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      for (final cls in unit.declarations.whereType<ClassDeclaration>()) {
        if (!hasYLintsAnnotation(cls.metadata, const {'FeatureCubit'})) {
          continue;
        }

        final fieldTypes = _collectFieldTypes(cls);

        for (final ctor in cls.members.whereType<ConstructorDeclaration>()) {
          for (final param in ctor.parameters.parameters) {
            final type = _resolveParamType(param, fieldTypes);
            if (type == null) continue;
            _checkType(type, reporter);
          }
        }
      }
    });
  }

  Map<String, TypeAnnotation?> _collectFieldTypes(ClassDeclaration cls) {
    final map = <String, TypeAnnotation?>{};
    for (final member in cls.members.whereType<FieldDeclaration>()) {
      final type = member.fields.type;
      for (final variable in member.fields.variables) {
        map[variable.name.lexeme] = type;
      }
    }
    return map;
  }

  TypeAnnotation? _resolveParamType(
    FormalParameter param,
    Map<String, TypeAnnotation?> fieldTypes,
  ) {
    final inner = param is DefaultFormalParameter ? param.parameter : param;
    if (inner is SimpleFormalParameter) return inner.type;
    if (inner is FieldFormalParameter) {
      return inner.type ?? fieldTypes[inner.name.lexeme];
    }
    return null;
  }

  void _checkType(TypeAnnotation type, ErrorReporter reporter) {
    if (type is! NamedType) return;
    final allowed = isAllowedBoundaryType(
      type.type,
      markerAnnotations: _allowed,
    );
    if (!allowed) reporter.atNode(type, _code);
  }
}
