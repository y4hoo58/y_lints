import 'package:y_lints/annotations.dart';

import '../../../models/user_model.dart';
import '../i_user_data_source.dart';

@MockDataSource()
class MockUserDataSource implements IUserDataSource {
  const MockUserDataSource();

  @override
  Future<UserModel> fetch(String id) async {
    return const UserModel(id: 'mock', name: 'Mock User');
  }
}
