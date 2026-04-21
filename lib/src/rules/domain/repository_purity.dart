import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../config/y_lints_config.dart';
import '../_shared/_architecture_rule.dart';

class RepositoryPurity extends ArchitectureRule {
  RepositoryPurity({YLintsConfig? config})
      : super(locationCode: _location, config: config);

  static const _location = LintCode(
    name: 'repository_location',
    problemMessage:
        '@Repository contracts must live under lib/domain/repositories/.',
  );

  @override
  String get annotationName => 'Repository';

  @override
  bool isAllowedPath(String filePath) =>
      filePath.contains(config.domainRepositories);
}
