import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';

/// Helpers for resolving annotations that must originate from
/// `package:y_lints/`.
///
/// Name-only matches (e.g. `a.name.name == 'Repository'`) cannot distinguish
/// between y_lints's `@Repository` and a same-named annotation from another
/// package, and silently accept typos whose import never resolves. Going
/// through the element model closes both holes.
const _yLintsPackagePrefix = 'package:y_lints/';

/// Returns the first annotation in [metadata] whose declaration lives in
/// `package:y_lints/` and has a class name in [names]; otherwise `null`.
Annotation? findYLintsAnnotation(
  Iterable<Annotation> metadata,
  Set<String> names,
) {
  for (final annotation in metadata) {
    if (_matchesAstAnnotation(annotation, names)) return annotation;
  }
  return null;
}

bool hasYLintsAnnotation(
  Iterable<Annotation> metadata,
  Set<String> names,
) =>
    findYLintsAnnotation(metadata, names) != null;

/// Variant for element-model metadata — used when walking a *referenced*
/// class (e.g. a supertype or the target of a type annotation), not the
/// class currently being linted.
bool elementHasYLintsAnnotation(
  InterfaceElement2 element,
  Set<String> names,
) {
  for (final annotation in element.metadata2.annotations) {
    if (_matchesElement(annotation.element2, names)) return true;
  }
  return false;
}

bool _matchesAstAnnotation(Annotation annotation, Set<String> names) {
  return _matchesElement(
    annotation.elementAnnotation?.element2,
    names,
  );
}

bool _matchesElement(Element2? element, Set<String> names) {
  String? className;
  Uri? libraryUri;
  if (element is ConstructorElement2) {
    className = element.enclosingElement2.name3;
    libraryUri = element.enclosingElement2.library2.uri;
  } else if (element is InterfaceElement2) {
    className = element.name3;
    libraryUri = element.library2.uri;
  }
  if (className == null || libraryUri == null) return false;
  if (!libraryUri.toString().startsWith(_yLintsPackagePrefix)) return false;
  return names.contains(className);
}
