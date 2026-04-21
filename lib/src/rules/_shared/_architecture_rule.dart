import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../config/y_lints_config.dart';
import 'y_lints_annotation.dart';

/// Shared base for architectural lint rules.
///
/// Subclasses declare:
///   - the annotation name they watch for (e.g. `DomainEntity`)
///   - an allowed-path predicate (location constraint)
///   - an optional filename predicate (used by mock datasource rule)
///
/// On match, violations are reported at the offending node (annotation node
/// for location/filename errors).
abstract class ArchitectureRule extends DartLintRule {
  ArchitectureRule({
    required LintCode locationCode,
    this.fileNameCode,
    YLintsConfig? config,
  })  : config = config ?? const YLintsConfig(),
        super(code: locationCode);

  String get annotationName;
  bool isAllowedPath(String filePath);
  bool isAllowedFileName(String fileName) => true;

  final LintCode? fileNameCode;
  final YLintsConfig config;

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.source.fullName;
    final fileName = filePath.split(RegExp(r'[/\\]')).last;

    context.registry.addCompilationUnit((unit) {
      final annotated = unit.declarations
          .whereType<ClassDeclaration>()
          .where(_isAnnotated)
          .toList();

      if (annotated.isEmpty) return;

      if (!isAllowedPath(filePath)) {
        for (final cls in annotated) {
          reporter.atNode(_annotationNode(cls) ?? cls, code);
        }
      }

      final nameCode = fileNameCode;
      if (nameCode != null && !isAllowedFileName(fileName)) {
        for (final cls in annotated) {
          reporter.atNode(_annotationNode(cls) ?? cls, nameCode);
        }
      }

      for (final cls in annotated) {
        checkClassStructure(cls, reporter);
      }
    });
  }

  /// Override to report extra per-class structural violations
  /// (e.g. "must extend a specific superclass").
  void checkClassStructure(ClassDeclaration node, ErrorReporter reporter) {}

  bool _isAnnotated(ClassDeclaration node) =>
      hasYLintsAnnotation(node.metadata, {annotationName});

  Annotation? _annotationNode(ClassDeclaration node) =>
      findYLintsAnnotation(node.metadata, {annotationName});
}
