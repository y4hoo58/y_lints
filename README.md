# y_lints

Custom lint rules that enforce clean architecture boundaries in Dart and
Flutter projects. Classes are tagged with simple annotations
(`@DomainEntity`, `@Repository`, `@DataSource`, `@FeatureCubit`, …) and the
lints verify that each tagged class lives in the right folder, follows the
right naming convention, and only depends on layers it is allowed to see.

Built on top of [`custom_lint`](https://pub.dev/packages/custom_lint).

## Installation

Add `custom_lint` and `y_lints` as dev dependencies:

```yaml
dev_dependencies:
  custom_lint: ^0.7.0
  y_lints: ^0.0.1
```

Enable the plugin in your `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint
```

Then run:

```sh
dart run custom_lint
```

## Usage

Import the annotations and tag your classes. The lints do the rest.

```dart
import 'package:y_lints/annotations.dart';

// lib/domain/entities/user_entity.dart
@DomainEntity()
class UserEntity {
  const UserEntity({required this.id, required this.name});
  final String id;
  final String name;
}

// lib/domain/repositories/user_repository.dart
@Repository()
abstract class UserRepository {
  Future<UserEntity> fetch(String id);
}

// lib/data/models/user_model.dart
@Model()
class UserModel extends UserEntity {
  const UserModel({required super.id, required super.name});
}
```

## Expected folder layout

```
lib/
├── domain/
│   ├── entities/              # @DomainEntity — pure entities
│   └── repositories/          # @Repository   — abstract contracts
├── data/
│   ├── models/                # @Model        — DTOs extending entities
│   ├── repositories/          # @RepositoryImpl
│   └── datasources/
│       └── <feature>/
│           ├── i_*.dart       # @DataSource   — contract
│           └── implementations/
│               ├── remote_*.dart  # @RemoteDataSource
│               └── mock_*.dart    # @MockDataSource
└── presentation/
    └── <feature>/
        ├── cubits/<cubit_name>/
        │   ├── *_cubit.dart   # @FeatureCubit
        │   └── *_state.dart   # @FeatureState
        ├── view/
        │   └── *_builder.dart # @FeatureBuilder — state consumer
        └── pages/             # @Page — any location, Page suffix
            └── *_page.dart
```

## Rules

| Rule | What it checks |
| --- | --- |
| `domain_entity_purity` | `@DomainEntity` classes live under `lib/domain/entities/`. |
| `repository_purity` | `@Repository` classes live under `lib/domain/repositories/`. |
| `repository_impl_purity` | `@RepositoryImpl` classes live under `lib/data/repositories/`. |
| `data_source_purity` | `@DataSource` contracts live under `lib/data/datasources/<feature>/` with an `i_` file prefix. |
| `remote_data_source_purity` | `@RemoteDataSource` classes live in `.../implementations/` with a `remote_` file prefix. |
| `mock_data_source_purity` | `@MockDataSource` classes live in `.../implementations/` with a `mock_` file prefix. |
| `model_purity` | `@Model` classes live under `lib/data/models/`, end in `_model.dart`, and extend an `*Entity`. |
| `feature_cubit_purity` | `@FeatureCubit` classes live under `lib/presentation/<feature>/cubits/<cubit_name>/` as `*_cubit.dart`. |
| `feature_state_purity` | `@FeatureState` classes live alongside their cubit as `*_state.dart`. |
| `page_purity` | `@Page` classes end with `Page`. |
| `feature_builder_purity` | `@FeatureBuilder` classes live under `lib/presentation/<feature>/view/`, end with `Builder`, and extend `StatelessWidget`/`StatefulWidget`. |
| `datasource_returns_model` | Datasource methods return `*Model` (or collections of them), not entities. |
| `repository_returns_entity` | Repository methods return `*Entity` (or collections of them), not models. |
| `datasource_import_boundary` | Datasources never import from `lib/domain/` or `lib/presentation/`. |
| `datasource_contract_implemented` | Each `@DataSource` contract has at least one implementation (`@RemoteDataSource` or `@MockDataSource`). |
| `cubit_constructor_dependencies` | Cubits only accept repository contracts as constructor dependencies. |
| `class_suffix_convention` | Public class names carry the suffix matching their layer (`Entity`, `Repository`, `Model`, `Cubit`, …). |
| `required_annotation` | Classes in each layer carry the annotation the layer requires. |

## Disabling a rule

Disable any rule in `analysis_options.yaml`:

```yaml
custom_lint:
  rules:
    - domain_entity_purity: false
```

## License

MIT — see [LICENSE](LICENSE).
