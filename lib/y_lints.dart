import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/class_suffix_convention.dart';
import 'src/rules/cubit_constructor_dependencies.dart';
import 'src/rules/data_source_purity.dart';
import 'src/rules/datasource_contract_implemented.dart';
import 'src/rules/datasource_import_boundary.dart';
import 'src/rules/datasource_returns_model.dart';
import 'src/rules/domain_entity_purity.dart';
import 'src/rules/feature_builder_purity.dart';
import 'src/rules/feature_cubit_purity.dart';
import 'src/rules/feature_state_purity.dart';
import 'src/rules/mock_data_source_purity.dart';
import 'src/rules/model_purity.dart';
import 'src/rules/page_purity.dart';
import 'src/rules/remote_data_source_purity.dart';
import 'src/rules/repository_impl_purity.dart';
import 'src/rules/repository_purity.dart';
import 'src/rules/repository_returns_entity.dart';
import 'src/rules/required_annotation.dart';

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
