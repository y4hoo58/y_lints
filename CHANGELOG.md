# Changelog

## 0.0.6

- Layer roots are now configurable via a `y_lints` block in
  `analysis_options.yaml`:

  ```yaml
  custom_lint:
    rules:
      - y_lints:
          root: lib/
          domain: domain/
          data: data/
          presentation: presentation/
  ```

  All four fields are optional; defaults match the prior hard-coded layout.
  Intra-layer folder names (`entities/`, `datasources/`, `cubits/`, …) and
  file conventions remain fixed.
- Removed `datasource_import_boundary` rule. Datasources are no longer
  gated by importer path — teams that need an import boundary can enforce
  it through their own lint rules or code review.

## 0.0.5

- Type and annotation classification across every rule now runs against
  the resolved element model instead of name/suffix matching. Enums,
  generic type parameters, `dart:core` value types, async/collection
  wrappers, and annotated classes are each recognized through the analyzer
  element API; a class called `FooEntity` that never declared
  `@DomainEntity` no longer satisfies boundary checks, and same-named
  annotations from unrelated packages no longer trip architectural rules.
- `repository_returns_entity` checks parameters again — now without
  false positives on enum parameters (`Gender`, `*Filter`, `*SortOrder`, …).
- `datasource_returns_model` accepts enum return types.
- `cubit_constructor_dependencies` requires real `@Repository` /
  `@DomainEntity` annotations on injected types; it no longer lets
  `*Repository`-suffixed infrastructure through.
- `feature_builder_must_be_widget` resolves the superclass and verifies it
  originates from `package:flutter/` — local stubs named
  `StatelessWidget`/`StatefulWidget` are rejected.
- `model_extends_entity` resolves the superclass element and requires
  `@DomainEntity` on it (the `Entity` name suffix is no longer sufficient).
- `datasource_contract_implemented` no longer uses the path/filename
  fallback — classes must carry `@RemoteDataSource` or `@MockDataSource`
  to be checked, and the contract must carry `@DataSource`.

## 0.0.4

- `repository_returns_entity` and `datasource_returns_model` now only check
  method **return types**. Parameter types are unconstrained — filter/query
  objects, request DTOs, auth tokens, and other non-`Entity`/`Model` types
  no longer trigger the rule.

## 0.0.3

- `class_suffix_convention` now accepts both `DataSource` and `Datasource`
  suffixes for classes under `lib/data/datasources/`.
- `datasource_contract_implemented` recognizes concrete datasources whose
  names end with either `DataSource` or `Datasource`.
- `domain_entity_purity` now enforces named-only constructor parameters on
  `@DomainEntity` classes (new `domain_entity_named_parameters` diagnostic).
  Both named required and named optional parameters are accepted; positional
  parameters are rejected.

## 0.0.2

- Add `@Page` annotation + `page_purity` rule: enforces `Page` suffix.
  Location and superclass are not constrained.
- Add `@FeatureBuilder` annotation + `feature_builder_purity` rule: enforces
  location under `lib/presentation/<feature>/view/`, `Builder` suffix, and
  `StatelessWidget`/`StatefulWidget` extension.

## 0.0.1

- Initial release.
- Architectural lint rules for domain, data, and presentation layers:
  - `domain_entity_purity`, `repository_purity`, `repository_impl_purity`
  - `data_source_purity`, `remote_data_source_purity`, `mock_data_source_purity`
  - `model_purity`, `datasource_returns_model`, `repository_returns_entity`
  - `feature_cubit_purity`, `feature_state_purity`
  - `datasource_import_boundary`, `datasource_contract_implemented`
  - `cubit_constructor_dependencies`, `class_suffix_convention`,
    `required_annotation`
- Annotations: `@DomainEntity`, `@Repository`, `@RepositoryImpl`,
  `@DataSource`, `@RemoteDataSource`, `@MockDataSource`, `@Model`,
  `@FeatureCubit`, `@FeatureState`.
