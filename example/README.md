# y_lints example

Full-layered project demonstrating every annotation and expected folder
layout `y_lints` checks for.

```sh
dart pub get
dart run custom_lint
```

## Layout

```
lib/
├── domain/
│   ├── entities/user_entity.dart          # @DomainEntity
│   └── repositories/user_repository.dart  # @Repository
├── data/
│   ├── models/user_model.dart             # @Model
│   ├── repositories/user_repository_impl.dart  # @RepositoryImpl
│   └── datasources/user/
│       ├── i_user_data_source.dart        # @DataSource
│       └── implementations/
│           ├── remote_user_data_source.dart  # @RemoteDataSource
│           └── mock_user_data_source.dart    # @MockDataSource
└── presentation/user/cubits/user_cubit/
    ├── user_cubit.dart                    # @FeatureCubit
    └── user_state.dart                    # @FeatureState
```

Move any file out of its expected folder — or drop its annotation — to see
the relevant rule fire.
