import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Flags `addListener` / `addObserver` calls that aren't paired with a
/// matching `removeListener` / `removeObserver` in the same class's
/// `dispose()` / `close()` method.
///
/// Listeners hold a strong reference to their callback. When the callback
/// closes over `this`, the target class can't be garbage-collected until
/// the listener is removed — even if the owning controller is disposed
/// later, anything held through the listener's closure leaks for the
/// interval. Explicitly pairing add/remove keeps the lifetime contract
/// obvious in code review.
///
/// Trigger: the class body defines a no-argument `dispose` or `close`
/// method. Without a lifecycle hook, the rule stays silent.
///
/// Matching rules:
///   - The `addListener` and its `removeListener` must share the same
///     *receiver name* (e.g. `_controller`, `widget`, `this.focusNode`
///     normalize to `_controller` / `widget` / `focusNode`).
///   - The first positional argument must be a simple identifier
///     (`_onChange`, `this._onChange`). Inline closures can't be removed
///     — they produce a new `Function` instance per call — and are always
///     flagged.
///
/// Unsupported forms (silently skipped to avoid false positives):
///   - complex receivers (`foo().addListener(...)`)
///   - computed callbacks (`addListener(_lookupHandler())`)
///   - disposal via a helper method called from `dispose()`
class ListenerLeak extends DartLintRule {
  const ListenerLeak() : super(code: _code);

  static const _code = LintCode(
    name: 'listener_leak',
    problemMessage:
        'Listener added without a matching removeListener/removeObserver '
        'in dispose()/close(). Anything captured by the callback leaks '
        'until the listener is explicitly removed.',
  );

  static const _closureCode = LintCode(
    name: 'listener_leak_closure',
    problemMessage:
        'Listener callback is an inline closure and cannot be removed. '
        'Extract it to a named method so dispose()/close() can call '
        'removeListener/removeObserver on the same reference.',
  );

  static const _addMethods = {'addListener', 'addObserver'};
  static const _removePair = {
    'addListener': 'removeListener',
    'addObserver': 'removeObserver',
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
    final disposeMethod = _lifecycleMethod(cls);
    if (disposeMethod == null) return;

    final addCollector = _ListenerCallCollector(_addMethods);
    for (final member in cls.members) {
      member.accept(addCollector);
    }
    if (addCollector.calls.isEmpty) return;

    final removeCollector =
        _ListenerCallCollector(_removePair.values.toSet());
    disposeMethod.body.accept(removeCollector);

    for (final add in addCollector.calls) {
      if (add.callback == null) {
        reporter.atNode(add.node, _closureCode);
        continue;
      }
      final expectedRemove = _removePair[add.method]!;
      final hasMatch = removeCollector.calls.any((r) =>
          r.method == expectedRemove &&
          r.receiver == add.receiver &&
          r.callback == add.callback);
      if (!hasMatch) {
        reporter.atNode(add.node, _code);
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
}

class _ListenerCall {
  _ListenerCall({
    required this.node,
    required this.method,
    required this.receiver,
    required this.callback,
  });

  final MethodInvocation node;
  final String method;
  final String receiver;

  /// `null` when the argument is an inline closure / complex expression.
  final String? callback;
}

class _ListenerCallCollector extends RecursiveAstVisitor<void> {
  _ListenerCallCollector(this.targetMethods);

  final Set<String> targetMethods;
  final List<_ListenerCall> calls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (targetMethods.contains(methodName)) {
      final receiver = _receiverName(node.target);
      final args = node.argumentList.arguments;
      final firstArg = args.isEmpty ? null : args.first;
      if (receiver != null && firstArg != null) {
        calls.add(_ListenerCall(
          node: node,
          method: methodName,
          receiver: receiver,
          callback: _argumentName(firstArg),
        ));
      }
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

  String? _argumentName(Expression arg) {
    final inner = arg is NamedExpression ? arg.expression : arg;
    if (inner is SimpleIdentifier) return inner.name;
    if (inner is PrefixedIdentifier) return inner.identifier.name;
    if (inner is PropertyAccess) return inner.propertyName.name;
    return null;
  }
}
