import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../config/y_lints_config.dart';
import '../_shared/_architecture_rule.dart';

class DomainEntityPurity extends ArchitectureRule {
  DomainEntityPurity({YLintsConfig? config})
      : super(locationCode: _location, config: config);

  static const _location = LintCode(
    name: 'domain_entity_location',
    problemMessage:
        '@DomainEntity classes must live under lib/domain/entities/.',
  );

  static const _namedOnly = LintCode(
    name: 'domain_entity_named_parameters',
    problemMessage:
        '@DomainEntity constructors must take named parameters only.',
  );

  static const _immutable = LintCode(
    name: 'domain_entity_immutable_fields',
    problemMessage: '@DomainEntity instance fields must be final.',
  );

  @override
  String get annotationName => 'DomainEntity';

  @override
  bool isAllowedPath(String filePath) =>
      filePath.contains(config.domainEntities);

  @override
  void checkClassStructure(ClassDeclaration node, ErrorReporter reporter) {
    for (final ctor in node.members.whereType<ConstructorDeclaration>()) {
      for (final param in ctor.parameters.parameters) {
        if (!param.isNamed) {
          reporter.atNode(param, _namedOnly);
        }
      }
    }
    for (final field in node.members.whereType<FieldDeclaration>()) {
      if (field.isStatic) continue;
      if (field.fields.isFinal || field.fields.isConst) continue;
      reporter.atNode(field, _immutable);
    }
  }
}
