import 'package:custom_lint_builder/custom_lint_builder.dart';

import '_architecture_rule.dart';

class RepositoryPurity extends ArchitectureRule {
  const RepositoryPurity() : super(locationCode: _location);

  static const _location = LintCode(
    name: 'repository_location',
    problemMessage:
        '@Repository contracts must live under lib/domain/repositories/.',
  );

  @override
  String get annotationName => 'Repository';

  @override
  bool isAllowedPath(String filePath) =>
      filePath.contains('/lib/domain/repositories/');
}
