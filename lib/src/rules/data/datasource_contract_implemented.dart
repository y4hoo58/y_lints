import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../_shared/y_lints_annotation.dart';

/// A concrete datasource implementation must bind to an abstract datasource.
///
/// Remote and mock datasources exist to back an abstract `@DataSource`
/// interface. If an implementation stands alone — or extends/implements
/// something that isn't a datasource contract — the mock/remote pair can
/// drift: one adds a method, the other forgets, and callers at the
/// repository layer silently couple to whichever concrete type they
/// happened to wire up.
///
/// This rule requires every class annotated `@RemoteDataSource` or
/// `@MockDataSource` to `extends` or `implements` a type that itself
/// carries the y_lints `@DataSource` annotation. Both the trigger and the
/// contract check use resolved element identity — nothing is matched by
/// name or filename.
class DatasourceContractImplemented extends DartLintRule {
  const DatasourceContractImplemented() : super(code: _code);

  static const _code = LintCode(
    name: 'datasource_contract_implemented',
    problemMessage:
        'Concrete datasource must extend or implement an abstract datasource — a class annotated with @DataSource.',
  );

  static const _concreteAnnotations = {
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
        if (!hasYLintsAnnotation(cls.metadata, _concreteAnnotations)) continue;

        final superType = cls.extendsClause?.superclass;
        final extendsContract =
            superType != null && _bindsToDataSourceContract(superType);
        final implementsContract =
            (cls.implementsClause?.interfaces ?? const <NamedType>[])
                .any(_bindsToDataSourceContract);

        if (extendsContract || implementsContract) continue;

        reporter.atNode(cls, _code);
      }
    });
  }

  bool _bindsToDataSourceContract(NamedType type) {
    final element = type.element2;
    if (element is! InterfaceElement2) return false;
    return elementHasYLintsAnnotation(element, const {'DataSource'});
  }
}
