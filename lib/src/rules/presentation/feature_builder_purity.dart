import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../_shared/_architecture_rule.dart';

/// Enforces `@FeatureBuilder` classes:
///   - live under `lib/presentation/<feature>/view/`
///   - end with `Builder`
///   - extend `StatelessWidget` or `StatefulWidget`
///
/// Intent: a feature builder is the widget that consumes a cubit's state
/// (typically wrapping `BlocBuilder`/`BlocConsumer`). Keeping it under
/// `view/` separates it from pages and keeps the per-feature layout
/// predictable.
class FeatureBuilderPurity extends ArchitectureRule {
  const FeatureBuilderPurity()
      : super(locationCode: _location);

  static const _location = LintCode(
    name: 'feature_builder_location',
    problemMessage:
        '@FeatureBuilder classes must live under lib/presentation/<feature>/view/.',
  );

  static const _suffix = LintCode(
    name: 'feature_builder_suffix',
    problemMessage: '@FeatureBuilder classes must end with "Builder".',
  );

  static const _widget = LintCode(
    name: 'feature_builder_must_be_widget',
    problemMessage:
        '@FeatureBuilder classes must extend StatelessWidget or StatefulWidget.',
  );

  static const _widgetBases = {'StatelessWidget', 'StatefulWidget'};

  static final RegExp _path =
      RegExp(r'/lib/presentation/[^/]+/view/[^/]+\.dart$');

  @override
  String get annotationName => 'FeatureBuilder';

  @override
  bool isAllowedPath(String filePath) => _path.hasMatch(filePath);

  @override
  void checkClassStructure(ClassDeclaration node, ErrorReporter reporter) {
    if (!node.name.lexeme.endsWith('Builder')) {
      reporter.atNode(node, _suffix);
    }
    final superName = node.extendsClause?.superclass.name2.lexeme;
    if (superName == null || !_widgetBases.contains(superName)) {
      reporter.atNode(node, _widget);
    }
  }
}
