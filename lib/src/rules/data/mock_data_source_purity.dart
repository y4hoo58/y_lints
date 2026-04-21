import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../config/y_lints_config.dart';
import '../_shared/_architecture_rule.dart';

class MockDataSourcePurity extends ArchitectureRule {
  MockDataSourcePurity({YLintsConfig? config})
      : super(
          locationCode: _location,
          fileNameCode: _fileName,
          config: config,
        );

  static const _location = LintCode(
    name: 'mock_data_source_location',
    problemMessage:
        '@MockDataSource classes must live in lib/data/datasources/<feature>/implementations/.',
  );

  static const _fileName = LintCode(
    name: 'mock_data_source_filename',
    problemMessage:
        '@MockDataSource files must be named mock_*.dart for discoverability.',
  );

  @override
  String get annotationName => 'MockDataSource';

  @override
  bool isAllowedPath(String filePath) =>
      config.datasourceImplementationPath.hasMatch(filePath);

  @override
  bool isAllowedFileName(String fileName) => fileName.startsWith('mock_');
}
