import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces the datasource import boundary from the *importer* side.
///
/// Datasources are a data-layer implementation detail. Only three places
/// are allowed to import them:
///
///   1. `lib/data/repositories/**` — the sole legitimate consumer;
///      repositories convert Models to Entities.
///   2. `lib/data/datasources/**`  — contract ↔ implementation self-imports
///      (e.g. a RemoteDataSource implementing its `i_*` interface).
///   3. `lib/app/di/**`            — the DI composition root needs to
///      instantiate concrete datasources to wire them into repositories.
///
/// Anywhere else — cubits, widgets, `core/` helpers, utilities — importing
/// a datasource is a leak that bypasses the repository boundary.
class DatasourceImportBoundary extends DartLintRule {
  const DatasourceImportBoundary() : super(code: _code);

  static const _code = LintCode(
    name: 'datasource_import_boundary',
    problemMessage:
        'Datasources may only be imported by lib/data/repositories/, other datasources, or lib/app/di/. Route through the repository contract instead.',
  );

  static final RegExp _datasourceImport =
      RegExp(r'^package:[^/]+/data/datasources/');

  static final List<RegExp> _allowedImporterPaths = [
    RegExp(r'/lib/data/repositories/'),
    RegExp(r'/lib/data/datasources/'),
    RegExp(r'/lib/app/di/'),
  ];

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.source.fullName;
    final importerAllowed =
        _allowedImporterPaths.any((re) => re.hasMatch(filePath));
    if (importerAllowed) return;

    context.registry.addCompilationUnit((unit) {
      for (final directive in unit.directives.whereType<ImportDirective>()) {
        final uri = directive.uri.stringValue ?? '';
        if (_datasourceImport.hasMatch(uri)) {
          reporter.atNode(directive, _code);
        }
      }
    });
  }
}
