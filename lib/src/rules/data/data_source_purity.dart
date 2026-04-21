import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../_shared/_architecture_rule.dart';

class DataSourcePurity extends ArchitectureRule {
  const DataSourcePurity()
      : super(
          locationCode: _location,
          fileNameCode: _fileName,
        );

  static const _location = LintCode(
    name: 'data_source_location',
    problemMessage:
        '@DataSource contracts must live in lib/data/datasources/<feature>/ (not inside implementations/).',
  );

  static const _fileName = LintCode(
    name: 'data_source_filename',
    problemMessage:
        '@DataSource files must be named i_*.dart to mark them as interfaces.',
  );

  @override
  String get annotationName => 'DataSource';

  @override
  bool isAllowedPath(String filePath) {
    const root = '/lib/data/datasources/';
    final idx = filePath.indexOf(root);
    if (idx < 0) return false;
    final tail = filePath.substring(idx + root.length);
    final segments = tail.split('/');
    // expected: <feature>/<file>.dart -> exactly 2 segments
    return segments.length == 2;
  }

  @override
  bool isAllowedFileName(String fileName) => fileName.startsWith('i_');
}
