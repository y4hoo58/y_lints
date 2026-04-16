import 'package:y_lints/annotations.dart';

@DomainEntity()
class UserEntity {
  const UserEntity({required this.id, required this.name});

  final String id;
  final String name;
}
