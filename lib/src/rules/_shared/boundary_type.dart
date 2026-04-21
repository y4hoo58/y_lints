import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';

import 'y_lints_annotation.dart';

/// Decides whether [type] is allowed to cross an architectural boundary
/// (repository method signatures, datasource return types, cubit ctor
/// parameters, etc.).
///
/// Classification runs against the resolved element — never the name — so a
/// class called `FooEntity` that lacks the marker annotation is correctly
/// rejected, and a properly-annotated class with a different suffix is
/// correctly accepted.
///
/// Allowed:
///   - `void`, `dynamic`, `Null`, `Object`
///   - core primitives: `bool`, `int`, `double`, `num`, `String`
///   - `dart:core` value types: `DateTime`, `Duration`, `Uri`
///   - async / collection wrappers (`Future`, `FutureOr`, `Stream`, `List`,
///     `Map`, `Set`, `Iterable`) whose type arguments are themselves allowed
///   - any enum
///   - unresolved type parameters (e.g. `T` on a generic repository)
///   - any class whose declaration carries a y_lints annotation whose name
///     is in [markerAnnotations]
bool isAllowedBoundaryType(
  DartType? type, {
  required Set<String> markerAnnotations,
}) {
  if (type == null || type is InvalidType) return true;
  if (type is VoidType || type is DynamicType) return true;
  if (type is TypeParameterType) return true;

  if (type.isDartCoreBool ||
      type.isDartCoreInt ||
      type.isDartCoreDouble ||
      type.isDartCoreNum ||
      type.isDartCoreString ||
      type.isDartCoreNull ||
      type.isDartCoreObject) {
    return true;
  }

  final isWrapper = type.isDartAsyncFuture ||
      type.isDartAsyncFutureOr ||
      type.isDartAsyncStream ||
      type.isDartCoreList ||
      type.isDartCoreMap ||
      type.isDartCoreSet ||
      type.isDartCoreIterable;
  if (isWrapper) {
    if (type is InterfaceType) {
      return type.typeArguments.every(
        (t) => isAllowedBoundaryType(t, markerAnnotations: markerAnnotations),
      );
    }
    return true;
  }

  if (type is! InterfaceType) return false;
  final element = type.element3;

  if (element is EnumElement2) return true;

  if (element.library2.uri.toString() == 'dart:core') {
    const coreValueTypes = {'DateTime', 'Duration', 'Uri'};
    if (coreValueTypes.contains(element.name3)) return true;
  }

  return elementHasYLintsAnnotation(element, markerAnnotations);
}
