import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A concrete datasource implementation must bind to an abstract datasource.
///
/// Remote and mock datasources exist to back an abstract `DataSource`
/// interface. If an implementation stands alone — or extends/implements
/// something that isn't a datasource contract — the mock/remote pair can
/// drift: one adds a method, the other forgets, and callers at the
/// repository layer silently couple to whichever concrete type they
/// happened to wire up.
///
/// This rule requires every concrete datasource class to `extends` or
/// `implements` a type that itself carries the `@DataSource` annotation.
/// A supertype whose name merely ends with `DataSource` is not enough —
/// only genuine contracts (classes declared with `@DataSource`) satisfy
/// the rule, so mixins, base utilities, or unrelated classes do not.
///
/// A class is considered a concrete datasource if:
///   1. it carries `@RemoteDataSource` or `@MockDataSource`, OR
///   2. it lives in a file named `remote_*.dart` or `mock_*.dart` under
///      `lib/data/datasources/**` and its class name ends with `DataSource`.
///
/// The filename/path fallback makes the rule useful before annotations
/// are applied across the codebase.
class DatasourceContractImplemented extends DartLintRule {
  const DatasourceContractImplemented() : super(code: _code);

  static const _code = LintCode(
    name: 'datasource_contract_implemented',
    problemMessage:
        'Concrete datasource must extend or implement an abstract datasource — a class annotated with @DataSource.',
  );

  static final RegExp _concreteFilePath = RegExp(
      r'/lib/data/datasources/.*/(remote|mock)_[^/]+\.dart$');

  static const _annotations = {'RemoteDataSource', 'MockDataSource'};

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.source.fullName;
    final filenameMatches = _concreteFilePath.hasMatch(filePath);

    context.registry.addCompilationUnit((unit) {
      for (final cls in unit.declarations.whereType<ClassDeclaration>()) {
        final name = cls.name.lexeme;
        if (name.startsWith('_')) continue;

        final annotated =
            cls.metadata.any((a) => _annotations.contains(a.name.name));
        final shapedLikeDatasource =
            filenameMatches && name.endsWith('DataSource');

        if (!annotated && !shapedLikeDatasource) continue;

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
    for (final annotation in element.metadata2.annotations) {
      final annoElement = annotation.element2;
      if (annoElement is! ConstructorElement2) continue;
      if (annoElement.enclosingElement2.name3 == 'DataSource') return true;
    }
    return false;
  }
}
