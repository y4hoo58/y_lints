import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Flags disposable fields that aren't cleaned up in `dispose()` / `close()`.
///
/// Trigger: the enclosing class declares a no-argument `dispose` or `close`
/// method *in its body* (inherited-only lifecycles are skipped — this keeps
/// false positives near zero).
///
/// A field is "disposable" when its declared type — or any supertype —
/// matches a known lifecycle-owning class:
///
///   - `package:flutter/` : `TextEditingController`, `ScrollController`,
///     `AnimationController`, `PageController`, `TabController`, `FocusNode`,
///     `ChangeNotifier`, `ValueNotifier`
///   - `dart:async`       : `StreamController` (close), `StreamSubscription`
///     (cancel), `Timer` (cancel)
///
/// For each disposable field, the rule scans the dispose/close method body
/// for an invocation of the expected cleanup method (`dispose`, `close`, or
/// `cancel`) with that field as the receiver. Missing call → lint fired on
/// the field declaration.
///
/// Receiver forms understood: `_field.dispose()`, `this._field.dispose()`,
/// `_field!.dispose()`, `_field?.dispose()`. Disposal through a helper
/// method (`_disposeAll()`) is not followed.
class DisposeLeak extends DartLintRule {
  const DisposeLeak() : super(code: _code);

  static const _code = LintCode(
    name: 'dispose_leak',
    problemMessage:
        'Disposable field is not disposed in dispose()/close(). '
        'Call .dispose() (or .close() / .cancel()) on it to avoid a leak.',
  );

  static const _registry = <String, Map<String, String>>{
    'package:flutter/': {
      'TextEditingController': 'dispose',
      'ScrollController': 'dispose',
      'AnimationController': 'dispose',
      'PageController': 'dispose',
      'TabController': 'dispose',
      'FocusNode': 'dispose',
      'ChangeNotifier': 'dispose',
      'ValueNotifier': 'dispose',
    },
    'dart:async': {
      'StreamController': 'close',
      'StreamSubscription': 'cancel',
      'Timer': 'cancel',
    },
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      for (final cls in unit.declarations.whereType<ClassDeclaration>()) {
        _checkClass(cls, reporter);
      }
    });
  }

  void _checkClass(ClassDeclaration cls, ErrorReporter reporter) {
    final lifecycleMethod = _lifecycleMethod(cls);
    if (lifecycleMethod == null) return;

    final disposables = <_Disposable>[];
    for (final field in cls.members.whereType<FieldDeclaration>()) {
      if (field.isStatic) continue;
      final type = field.fields.type;
      if (type is! NamedType) continue;
      final element = type.element2;
      if (element is! InterfaceElement2) continue;
      final method = _cleanupMethodFor(element);
      if (method == null) continue;
      for (final variable in field.fields.variables) {
        disposables.add(_Disposable(
          node: field,
          fieldName: variable.name.lexeme,
          expectedMethod: method,
        ));
      }
    }
    if (disposables.isEmpty) return;

    final invocations = <String, Set<String>>{};
    final collector = _CleanupCallCollector(invocations);
    lifecycleMethod.body.accept(collector);

    for (final d in disposables) {
      final called = invocations[d.fieldName];
      if (called == null || !called.contains(d.expectedMethod)) {
        reporter.atNode(d.node, _code);
      }
    }
  }

  MethodDeclaration? _lifecycleMethod(ClassDeclaration cls) {
    for (final member in cls.members.whereType<MethodDeclaration>()) {
      final name = member.name.lexeme;
      if (name != 'dispose' && name != 'close') continue;
      final params = member.parameters?.parameters ?? const <FormalParameter>[];
      if (params.isNotEmpty) continue;
      return member;
    }
    return null;
  }

  String? _cleanupMethodFor(InterfaceElement2 element) {
    final direct = _lookup(element);
    if (direct != null) return direct;
    for (final supertype in element.allSupertypes) {
      final match = _lookup(supertype.element3);
      if (match != null) return match;
    }
    return null;
  }

  String? _lookup(InterfaceElement2 element) {
    final uri = element.library2.uri.toString();
    final name = element.name3;
    if (name == null) return null;
    for (final entry in _registry.entries) {
      if (uri.startsWith(entry.key)) {
        final method = entry.value[name];
        if (method != null) return method;
      }
    }
    return null;
  }
}

class _Disposable {
  _Disposable({
    required this.node,
    required this.fieldName,
    required this.expectedMethod,
  });
  final FieldDeclaration node;
  final String fieldName;
  final String expectedMethod;
}

class _CleanupCallCollector extends RecursiveAstVisitor<void> {
  _CleanupCallCollector(this.invocations);

  /// receiverName → set of method names invoked on it
  final Map<String, Set<String>> invocations;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final receiver = _receiverName(node.target);
    if (receiver != null) {
      invocations.putIfAbsent(receiver, () => <String>{}).add(
            node.methodName.name,
          );
    }
    super.visitMethodInvocation(node);
  }

  String? _receiverName(Expression? target) {
    if (target == null) return null;
    if (target is SimpleIdentifier) return target.name;
    if (target is PrefixedIdentifier) return target.identifier.name;
    if (target is PropertyAccess) return target.propertyName.name;
    if (target is PostfixExpression) return _receiverName(target.operand);
    if (target is ParenthesizedExpression) {
      return _receiverName(target.expression);
    }
    return null;
  }
}
