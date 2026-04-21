import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../_shared/y_lints_annotation.dart';

/// Blocks datasources from reaching `@FeatureCubit` constructors.
///
/// Cubits are presentation orchestrators. Repositories, value objects, and
/// the user's own services are all fair game — but datasources should
/// never be injected directly: they're the concrete infrastructure that
/// repositories exist to hide.
///
/// Rejected parameter types (including inside `Future<…>`, `List<…>`, …):
///   - any class carrying `@DataSource`, `@RemoteDataSource`, or
///     `@MockDataSource`
///
/// Everything else is allowed. Detection runs against the resolved
/// element's annotation — never the name.
///
/// Resolution covers:
///   - `FooCubit(AuthDataSource ds)`               (plain parameter)
///   - `FooCubit({required AuthDataSource ds})`    (named/optional)
///   - `FooCubit(this._authDataSource)`            (field-initialising;
///     falls back to the field's declared type when the parameter has
///     no explicit annotation)
///
/// `super.x` and function-typed parameters are skipped.
class CubitConstructorDependencies extends DartLintRule {
  const CubitConstructorDependencies() : super(code: _code);

  static const _code = LintCode(
    name: 'cubit_constructor_dependencies',
    problemMessage:
        '@FeatureCubit constructors must not depend on datasources. Route through a @Repository contract.',
  );

  static const _forbiddenAnnotations = {
    'DataSource',
    'RemoteDataSource',
    'MockDataSource',
  };

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
    if (_containsForbidden(type.type)) {
      reporter.atNode(type, _code);
    }
  }

  bool _containsForbidden(DartType? type) {
    if (type is! InterfaceType) return false;
    if (elementHasYLintsAnnotation(type.element3, _forbiddenAnnotations)) {
      return true;
    }
    return type.typeArguments.any(_containsForbidden);
  }
}
