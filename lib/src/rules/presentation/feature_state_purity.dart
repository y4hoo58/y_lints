import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../_shared/_architecture_rule.dart';

class FeatureStatePurity extends ArchitectureRule {
  const FeatureStatePurity()
      : super(
          locationCode: _location,
          fileNameCode: _fileName,
        );

  static const _location = LintCode(
    name: 'feature_state_location',
    problemMessage:
        '@FeatureState classes must live next to their cubit in lib/presentation/<feature>/cubits/<cubit_name>/.',
  );

  static const _fileName = LintCode(
    name: 'feature_state_filename',
    problemMessage: '@FeatureState files must be named *_state.dart.',
  );

  @override
  String get annotationName => 'FeatureState';

  @override
  bool isAllowedPath(String filePath) {
    return RegExp(r'/lib/presentation/[^/]+/cubits/[^/]+/[^/]+\.dart$')
        .hasMatch(filePath);
  }

  @override
  bool isAllowedFileName(String fileName) => fileName.endsWith('_state.dart');
}
