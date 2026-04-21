import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../config/y_lints_config.dart';
import '../_shared/_architecture_rule.dart';

/// Enforces `@FeatureBuilder` classes:
///   - live under `lib/presentation/<feature>/view/`
///   - end with `Builder`
///   - extend Flutter's `StatelessWidget` or `StatefulWidget`
///
/// The widget-base check resolves the superclass element and verifies it
/// originates from `package:flutter/` — a user-defined class merely named
/// `StatelessWidget` will not satisfy the rule.
class FeatureBuilderPurity extends ArchitectureRule {
  FeatureBuilderPurity({YLintsConfig? config})
      : super(locationCode: _location, config: config);

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

  static const _flutterWidgetNames = {'StatelessWidget', 'StatefulWidget'};

  @override
  String get annotationName => 'FeatureBuilder';

  @override
  bool isAllowedPath(String filePath) =>
      config.featureViewPath.hasMatch(filePath);

  @override
  void checkClassStructure(ClassDeclaration node, ErrorReporter reporter) {
    if (!node.name.lexeme.endsWith('Builder')) {
      reporter.atNode(node, _suffix);
    }
    final superclass = node.extendsClause?.superclass;
    if (superclass == null || !_isFlutterWidgetBase(superclass)) {
      reporter.atNode(node, _widget);
    }
  }

  static bool _isFlutterWidgetBase(NamedType superclass) {
    final element = superclass.element2;
    if (element is! InterfaceElement2) return false;
    if (!_flutterWidgetNames.contains(element.name3)) return false;
    return element.library2.uri.toString().startsWith('package:flutter/');
  }
}
