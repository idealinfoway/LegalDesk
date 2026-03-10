import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 10)
class UserModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String city;

  @HiveField(5)
  String state;

  @HiveField(6)
  String photoUrl;

  @HiveField(7)
  DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.city = '',
    this.state = '',
    this.photoUrl = '',
    required this.createdAt,
  });
}
