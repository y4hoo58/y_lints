/// Marks a class as a pure domain entity.
///
/// Enforced by `domain_entity_purity`:
/// - Must live in `lib/domain/entities/`.
class DomainEntity {
  const DomainEntity();
}

/// Marks a class as an abstract repository contract.
///
/// Enforced by `repository_purity`:
/// - Must live in `lib/domain/repositories/`.
class Repository {
  const Repository();
}

/// Marks a class as a concrete repository implementation.
///
/// Enforced by `repository_impl_purity`:
/// - Must live in `lib/data/repositories/`.
class RepositoryImpl {
  const RepositoryImpl();
}

/// Marks a class as an abstract datasource contract.
///
/// Enforced by `data_source_purity`:
/// - Must live in `lib/data/datasources/<feature>/` (not in `implementations/`).
/// - File name must start with `i_`.
class DataSource {
  const DataSource();
}

/// Marks a class as a remote (network-backed) datasource implementation.
///
/// Enforced by `remote_data_source_purity`:
/// - Must live in `lib/data/datasources/<feature>/implementations/`.
/// - File name must start with `remote_`.
class RemoteDataSource {
  const RemoteDataSource();
}

/// Marks a class as a data-layer model (DTO) backed by a domain entity.
///
/// Enforced by `model_purity`:
/// - Must live in `lib/data/models/`.
/// - File name must end with `_model.dart`.
/// - Must extend a class whose name ends with `Entity` (e.g.
///   `class LanguageModel extends LanguageEntity`).
class Model {
  const Model();
}

/// Marks a class as a feature cubit's state.
///
/// Enforced by `feature_state_purity`:
/// - Must live alongside its cubit: `lib/presentation/<feature>/cubits/<cubit_name>/`.
/// - File name must end with `_state.dart`.
class FeatureState {
  const FeatureState();
}

/// Marks a class as a presentation-layer feature cubit.
///
/// Enforced by `feature_cubit_purity`:
/// - Must live in `lib/presentation/<feature>/cubits/<cubit_name>/`.
/// - File name must end with `_cubit.dart`.
class FeatureCubit {
  const FeatureCubit();
}

/// Marks a class as a mock/offline datasource implementation.
///
/// Enforced by `mock_data_source_purity`:
/// - Must live in `lib/data/datasources/<feature>/implementations/`.
/// - File name must start with `mock_`.
class MockDataSource {
  const MockDataSource();
}

/// Marks a class as a routable page.
///
/// Enforced by `page_purity`:
/// - Class name must end with `Page`.
///
/// Location and superclass are intentionally not constrained.
class Page {
  const Page();
}

/// Marks a widget class as a cubit-state consumer (typically wrapping
/// `BlocBuilder`/`BlocConsumer`).
///
/// Enforced by `feature_builder_purity`:
/// - Must live in `lib/presentation/<feature>/view/`.
/// - Class name must end with `Builder`.
/// - Must extend `StatelessWidget` or `StatefulWidget`.
class FeatureBuilder {
  const FeatureBuilder();
}
