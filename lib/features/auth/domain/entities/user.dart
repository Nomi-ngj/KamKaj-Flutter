import 'package:equatable/equatable.dart';

final class User extends Equatable {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.isEmailVerified = true,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final bool isEmailVerified;

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [id, firstName, lastName, email, isEmailVerified];
}
