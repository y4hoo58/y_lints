import 'package:custom_lint_builder/custom_lint_builder.dart';

import '_architecture_rule.dart';

class FeatureCubitPurity extends ArchitectureRule {
  const FeatureCubitPurity()
      : super(
          locationCode: _location,
          fileNameCode: _fileName,
        );

  static const _location = LintCode(
    name: 'feature_cubit_location',
    problemMessage:
        '@FeatureCubit classes must live in lib/presentation/<feature>/cubits/<cubit_name>/.',
  );

  static const _fileName = LintCode(
    name: 'feature_cubit_filename',
    problemMessage: '@FeatureCubit files must be named *_cubit.dart.',
  );

  @override
  String get annotationName => 'FeatureCubit';

  @override
  bool isAllowedPath(String filePath) {
    return RegExp(r'/lib/presentation/[^/]+/cubits/[^/]+/[^/]+\.dart$')
        .hasMatch(filePath);
  }

  @override
  bool isAllowedFileName(String fileName) => fileName.endsWith('_cubit.dart');
}
