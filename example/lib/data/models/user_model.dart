import 'package:y_lints/annotations.dart';

import '../../domain/entities/user_entity.dart';

@Model()
class UserModel extends UserEntity {
  const UserModel({required super.id, required super.name});

  factory UserModel.fromJson(Map<String, Object?> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
