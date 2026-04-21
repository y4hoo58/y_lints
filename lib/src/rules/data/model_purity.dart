import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../_shared/_architecture_rule.dart';
import '../_shared/y_lints_annotation.dart';

class ModelPurity extends ArchitectureRule {
  const ModelPurity()
      : super(
          locationCode: _location,
          fileNameCode: _fileName,
        );

  static const _location = LintCode(
    name: 'model_location',
    problemMessage: '@Model classes must live in lib/data/models/.',
  );

  static const _fileName = LintCode(
    name: 'model_filename',
    problemMessage: '@Model files must be named *_model.dart.',
  );

  static const _extends = LintCode(
    name: 'model_extends_entity',
    problemMessage: '@Model classes must extend a @DomainEntity class.',
  );

  @override
  String get annotationName => 'Model';

  @override
  bool isAllowedPath(String filePath) =>
      filePath.contains('/lib/data/models/');

  @override
  bool isAllowedFileName(String fileName) => fileName.endsWith('_model.dart');

  @override
  void checkClassStructure(ClassDeclaration node, ErrorReporter reporter) {
    final superclass = node.extendsClause?.superclass;
    if (superclass == null) {
      reporter.atNode(node, _extends);
      return;
    }
    final element = superclass.element2;
    if (element is! InterfaceElement2 ||
        !elementHasYLintsAnnotation(element, const {'DomainEntity'})) {
      reporter.atNode(node, _extends);
    }
  }
}
