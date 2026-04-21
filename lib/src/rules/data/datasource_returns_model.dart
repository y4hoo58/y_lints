import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../_shared/boundary_type.dart';
import '../_shared/y_lints_annotation.dart';

/// Ensures datasource method signatures only expose data-safe types.
///
/// Classification runs against the resolved type element, not the name:
///   - `void`, primitives (`bool`, `int`, `double`, `num`, `String`),
///     `dart:core` value types (`DateTime`, `Duration`, `Uri`), `dynamic`,
///     `Null`, `Object`
///   - async / collection wrappers (`Future`, `FutureOr`, `Stream`, `List`,
///     `Map`, `Set`, `Iterable`) whose inner types are themselves allowed
///   - any enum
///   - unresolved type parameters
///   - any class carrying `@Model`
///
/// Anything else — notably `*Entity` domain types, or model-suffixed
/// classes that never declared `@Model` — triggers the rule. The DTO
/// boundary must live at the datasource; entities only appear once the
/// repository has converted them.
class DatasourceReturnsModel extends DartLintRule {
  const DatasourceReturnsModel() : super(code: _code);

  static const _code = LintCode(
    name: 'datasource_returns_model',
    problemMessage:
        'Datasource methods must return @Model types, enums, primitives, or void. Convert to Entity inside the repository.',
  );

  static const _datasourceAnnotations = {
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
        if (!hasYLintsAnnotation(cls.metadata, _datasourceAnnotations)) {
          continue;
        }

        for (final member in cls.members.whereType<MethodDeclaration>()) {
          _checkType(member.returnType, reporter);
        }
      }
    });
  }

  void _checkType(TypeAnnotation? annotation, ErrorReporter reporter) {
    if (annotation is! NamedType) return;
    final allowed = isAllowedBoundaryType(
      annotation.type,
      markerAnnotations: const {'Model'},
    );
    if (!allowed) reporter.atNode(annotation, _code);
  }
}
