import 'package:y_lints/annotations.dart';

import '../../../../domain/repositories/user_repository.dart';
import 'user_state.dart';

@FeatureCubit()
class UserCubit {
  UserCubit(this._repository);

  final UserRepository _repository;

  UserState state = const UserInitial();

  Future<void> load(String id) async {
    state = const UserLoading();
    try {
      final user = await _repository.fetch(id);
      state = UserLoaded(user);
    } catch (e) {
      state = UserError(e.toString());
    }
  }
}
