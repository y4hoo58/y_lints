import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '_architecture_rule.dart';

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
    problemMessage:
        '@Model classes must extend a domain entity (a class whose name ends with "Entity").',
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
    final superName = node.extendsClause?.superclass.name2.lexeme;
    if (superName == null || !superName.endsWith('Entity')) {
      reporter.atNode(node.name.length > 0 ? node : node, _extends);
    }
  }
}
