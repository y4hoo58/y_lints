# Changelog

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
