import 'package:y_lints/annotations.dart';

import '../entities/user_entity.dart';

@Repository()
abstract class UserRepository {
  Future<UserEntity> fetch(String id);
}
