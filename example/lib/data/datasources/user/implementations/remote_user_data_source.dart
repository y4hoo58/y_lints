import 'package:y_lints/annotations.dart';

import '../../../models/user_model.dart';
import '../i_user_data_source.dart';

@RemoteDataSource()
class RemoteUserDataSource implements IUserDataSource {
  const RemoteUserDataSource();

  @override
  Future<UserModel> fetch(String id) async {
    return const UserModel(id: '1', name: 'Ada');
  }
}
