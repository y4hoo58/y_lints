import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../_shared/y_lints_annotation.dart';

/// Enforces the suffix on `@Page`-annotated classes.
///
/// Location and superclass are intentionally not constrained — pages are
/// identified by name only. A page must end its class name with `Page`.
class PagePurity extends DartLintRule {
  const PagePurity() : super(code: _suffix);

  static const _suffix = LintCode(
    name: 'page_suffix',
    problemMessage: '@Page classes must end with "Page".',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      for (final cls in unit.declarations.whereType<ClassDeclaration>()) {
        final anno = findYLintsAnnotation(cls.metadata, const {'Page'});
        if (anno == null) continue;

        if (!cls.name.lexeme.endsWith('Page')) {
          reporter.atNode(anno, _suffix);
        }
      }
    });
  }
}
