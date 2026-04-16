# Changelog

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
