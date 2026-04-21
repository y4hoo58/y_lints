import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/config/y_lints_config.dart';
import 'src/rules/_shared/class_suffix_convention.dart';
import 'src/rules/_shared/required_annotation.dart';
import 'src/rules/data/datasource_contract_implemented.dart';
import 'src/rules/data/datasource_purity.dart';
import 'src/rules/data/datasource_returns_model.dart';
import 'src/rules/data/mock_datasource_purity.dart';
import 'src/rules/data/model_purity.dart';
import 'src/rules/data/remote_datasource_purity.dart';
import 'src/rules/data/repository_impl_purity.dart';
import 'src/rules/domain/domain_entity_purity.dart';
import 'src/rules/domain/repository_purity.dart';
import 'src/rules/domain/repository_returns_entity.dart';
import 'src/rules/hygiene/dispose_leak.dart';
import 'src/rules/presentation/cubit_constructor_dependencies.dart';
import 'src/rules/presentation/feature_builder_purity.dart';
import 'src/rules/presentation/feature_cubit_purity.dart';
import 'src/rules/presentation/feature_state_purity.dart';
import 'src/rules/presentation/page_purity.dart';

PluginBase createPlugin() => _YLints();

class _YLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    final config = YLintsConfig.fromLintConfigs(configs);
    return [
      DomainEntityPurity(config: config),
      RepositoryPurity(config: config),
      RepositoryImplPurity(config: config),
      DataSourcePurity(config: config),
      RemoteDataSourcePurity(config: config),
      MockDataSourcePurity(config: config),
      FeatureCubitPurity(config: config),
      FeatureStatePurity(config: config),
      ModelPurity(config: config),
      const DatasourceReturnsModel(),
      const RepositoryReturnsEntity(),
      RequiredAnnotation(config: config),
      const CubitConstructorDependencies(),
      ClassSuffixConvention(config: config),
      const DatasourceContractImplemented(),
      const PagePurity(),
      FeatureBuilderPurity(config: config),
      const DisposeLeak(),
    ];
  }
}
