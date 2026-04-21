import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../_shared/_architecture_rule.dart';

class RemoteDataSourcePurity extends ArchitectureRule {
  const RemoteDataSourcePurity()
      : super(
          locationCode: _location,
          fileNameCode: _fileName,
        );

  static const _location = LintCode(
    name: 'remote_data_source_location',
    problemMessage:
        '@RemoteDataSource classes must live in lib/data/datasources/<feature>/implementations/.',
  );

  static const _fileName = LintCode(
    name: 'remote_data_source_filename',
    problemMessage:
        '@RemoteDataSource files must be named remote_*.dart.',
  );

  @override
  String get annotationName => 'RemoteDataSource';

  @override
  bool isAllowedPath(String filePath) {
    final match = RegExp(r'/lib/data/datasources/[^/]+/implementations/[^/]+\.dart$')
        .hasMatch(filePath);
    return match;
  }

  @override
  bool isAllowedFileName(String fileName) => fileName.startsWith('remote_');
}
