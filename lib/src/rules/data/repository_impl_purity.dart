import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../config/y_lints_config.dart';
import '../_shared/_architecture_rule.dart';

class RepositoryImplPurity extends ArchitectureRule {
  RepositoryImplPurity({YLintsConfig? config})
      : super(locationCode: _location, config: config);

  static const _location = LintCode(
    name: 'repository_impl_location',
    problemMessage:
        '@RepositoryImpl classes must live under lib/data/repositories/.',
  );

  @override
  String get annotationName => 'RepositoryImpl';

  @override
  bool isAllowedPath(String filePath) =>
      filePath.contains(config.dataRepositories);
}
