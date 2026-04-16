import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Restricts what a `@FeatureCubit` constructor is allowed to depend on.
///
/// Cubits are presentation orchestrators. They should talk to the domain
/// through repository contracts — nothing else. This rule inspects every
/// constructor parameter on a `@FeatureCubit` class and accepts only:
///
///   - primitives: `bool`, `int`, `double`, `num`, `String`, `DateTime`,
///     `Uri`, `Duration`, `dynamic`, `Object`, `Null`
///   - types whose name ends with `Repository` (domain contracts)
///   - types whose name ends with `Entity` (initial/seed domain data)
///   - wrappers over any of the above: `Future`, `FutureOr`, `Stream`,
///     `List`, `Map`, `Set`, `Iterable`
///
/// Everything else — `*Impl`, `*DataSource`, `Dio`, `http.Client`,
/// `SharedPreferences`, `FlutterSecureStorage`, random infrastructure — is
/// rejected. Cubits must not smuggle infrastructure in "just this once".
///
/// Resolution covers:
///   - `FooCubit(AuthRepository repo)` (plain parameter)
///   - `FooCubit({required AuthRepository repo})` (named/optional)
///   - `FooCubit(this._authRepository)` (field-initialising; looks up the
///     field's declared type when the parameter itself has no annotation)
///
/// `super.x` and function-typed parameters are skipped — they can't be
/// resolved from the AST alone without the element model.
class CubitConstructorDependencies extends DartLintRule {
  const CubitConstructorDependencies() : super(code: _code);

  static const _code = LintCode(
    name: 'cubit_constructor_dependencies',
    problemMessage:
        '@FeatureCubit constructors may only depend on *Repository contracts (plus primitives/entities). Inject a repository, not a *Impl, *DataSource, Dio, or other infrastructure.',
  );

  static const _allowedTypeNames = {
    'void',
    'bool',
    'int',
    'double',
    'num',
    'String',
    'DateTime',
    'Uri',
    'Duration',
    'dynamic',
    'Object',
    'Null',
  };

  static const _wrapperTypeNames = {
    'Future',
    'FutureOr',
    'Stream',
    'List',
    'Map',
    'Set',
    'Iterable',
  };

  static final RegExp _cubitFilePath =
      RegExp(r'/lib/presentation/.*_cubit\.dart$');

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final filePath = resolver.source.fullName;
    if (!_cubitFilePath.hasMatch(filePath)) return;

    context.registry.addCompilationUnit((unit) {
      for (final cls in unit.declarations.whereType<ClassDeclaration>()) {
        final isCubit = cls.name.lexeme.endsWith('Cubit') ||
            cls.metadata.any((a) => a.name.name == 'FeatureCubit');
        if (!isCubit) continue;

        final fieldTypes = _collectFieldTypes(cls);

        for (final ctor in cls.members.whereType<ConstructorDeclaration>()) {
          for (final param in ctor.parameters.parameters) {
            final type = _resolveParamType(param, fieldTypes);
            if (type == null) continue;
            _checkType(type, reporter);
          }
        }
      }
    });
  }

  Map<String, TypeAnnotation?> _collectFieldTypes(ClassDeclaration cls) {
    final map = <String, TypeAnnotation?>{};
    for (final member in cls.members.whereType<FieldDeclaration>()) {
      final type = member.fields.type;
      for (final variable in member.fields.variables) {
        map[variable.name.lexeme] = type;
      }
    }
    return map;
  }

  TypeAnnotation? _resolveParamType(
    FormalParameter param,
    Map<String, TypeAnnotation?> fieldTypes,
  ) {
    final inner = param is DefaultFormalParameter ? param.parameter : param;
    if (inner is SimpleFormalParameter) return inner.type;
    if (inner is FieldFormalParameter) {
      return inner.type ?? fieldTypes[inner.name.lexeme];
    }
    return null;
  }

  void _checkType(TypeAnnotation type, ErrorReporter reporter) {
    if (type is! NamedType) return;
    final name = type.name2.lexeme;
    final args = type.typeArguments?.arguments ?? const <TypeAnnotation>[];

    if (_wrapperTypeNames.contains(name)) {
      for (final arg in args) {
        _checkType(arg, reporter);
      }
      return;
    }
    if (_allowedTypeNames.contains(name)) return;
    if (name.endsWith('Repository')) return;
    if (name.endsWith('Entity')) return;

    reporter.atNode(type, _code);
  }
}
