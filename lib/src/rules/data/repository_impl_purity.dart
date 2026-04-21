import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../_shared/_architecture_rule.dart';

class RepositoryImplPurity extends ArchitectureRule {
  const RepositoryImplPurity() : super(locationCode: _location);

  static const _location = LintCode(
    name: 'repository_impl_location',
    problemMessage:
        '@RepositoryImpl classes must live under lib/data/repositories/.',
  );

  @override
  String get annotationName => 'RepositoryImpl';

  @override
  bool isAllowedPath(String filePath) =>
      filePath.contains('/lib/data/repositories/');
}
