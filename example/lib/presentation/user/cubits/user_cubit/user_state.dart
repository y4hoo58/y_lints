import 'package:y_lints/annotations.dart';

import '../../../../domain/entities/user_entity.dart';

@FeatureState()
sealed class UserState {
  const UserState();
}

class UserInitial extends UserState {
  const UserInitial();
}

class UserLoading extends UserState {
  const UserLoading();
}

class UserLoaded extends UserState {
  const UserLoaded(this.user);
  final UserEntity user;
}

class UserError extends UserState {
  const UserError(this.message);
  final String message;
}
