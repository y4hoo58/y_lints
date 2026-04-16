import 'package:y_lints/annotations.dart';

import '../../models/user_model.dart';

@DataSource()
abstract class IUserDataSource {
  Future<UserModel> fetch(String id);
}
