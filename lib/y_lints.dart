import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/_shared/class_suffix_convention.dart';
import 'src/rules/_shared/required_annotation.dart';
import 'src/rules/data/data_source_purity.dart';
import 'src/rules/data/datasource_contract_implemented.dart';
import 'src/rules/data/datasource_import_boundary.dart';
import 'src/rules/data/datasource_returns_model.dart';
import 'src/rules/data/mock_data_source_purity.dart';
import 'src/rules/data/model_purity.dart';
import 'src/rules/data/remote_data_source_purity.dart';
import 'src/rules/data/repository_impl_purity.dart';
import 'src/rules/domain/domain_entity_purity.dart';
import 'src/rules/domain/repository_purity.dart';
import 'src/rules/domain/repository_returns_entity.dart';
import 'src/rules/presentation/cubit_constructor_dependencies.dart';
import 'src/rules/presentation/feature_builder_purity.dart';
import 'src/rules/presentation/feature_cubit_purity.dart';
import 'src/rules/presentation/feature_state_purity.dart';
import 'src/rules/presentation/page_purity.dart';

PluginBase createPlugin() => _YLints();

class _YLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
        DomainEntityPurity(),
        RepositoryPurity(),
        RepositoryImplPurity(),
        DataSourcePurity(),
        RemoteDataSourcePurity(),
        MockDataSourcePurity(),
        FeatureCubitPurity(),
        FeatureStatePurity(),
        ModelPurity(),
        DatasourceReturnsModel(),
        RepositoryReturnsEntity(),
        RequiredAnnotation(),
        DatasourceImportBoundary(),
        CubitConstructorDependencies(),
        ClassSuffixConvention(),
        DatasourceContractImplemented(),
        PagePurity(),
        FeatureBuilderPurity(),
      ];
}
