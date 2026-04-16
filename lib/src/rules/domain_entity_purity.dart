import 'package:custom_lint_builder/custom_lint_builder.dart';

import '_architecture_rule.dart';

class DomainEntityPurity extends ArchitectureRule {
  const DomainEntityPurity() : super(locationCode: _location);

  static const _location = LintCode(
    name: 'domain_entity_location',
    problemMessage:
        '@DomainEntity classes must live under lib/domain/entities/.',
  );

  @override
  String get annotationName => 'DomainEntity';

  @override
  bool isAllowedPath(String filePath) =>
      filePath.contains('/lib/domain/entities/');
}
