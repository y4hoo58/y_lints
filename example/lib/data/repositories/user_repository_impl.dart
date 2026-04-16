import 'package:y_lints/annotations.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user/i_user_data_source.dart';

@RepositoryImpl()
class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._dataSource);

  final IUserDataSource _dataSource;

  @override
  Future<UserEntity> fetch(String id) => _dataSource.fetch(id);
}
