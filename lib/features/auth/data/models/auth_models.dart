import '../../../../core/utils/json_reader.dart';
import '../../domain/entities/user.dart';

final class UserModel {
  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isEmailVerified,
  });

  factory UserModel.fromJson(Map<String, Object?> json) => UserModel(
        id: json.readString('id'),
        firstName: json.readString('firstName'),
        lastName: json.readString('lastName'),
        email: json.readString('email'),
        isEmailVerified: json.readBool('emailVerified', fallback: true),
      );

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final bool isEmailVerified;

  Map<String, Object?> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'emailVerified': isEmailVerified,
      };

  User toEntity() => User(
        id: id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        isEmailVerified: isEmailVerified,
      );
}

/// Token pair + user returned by sign-in and sign-up verification.
final class AuthResponseModel {
  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, Object?> json) {
    final user = json['user'];
    return AuthResponseModel(
      accessToken: json.readString('accessToken'),
      refreshToken: json.readString('refreshToken'),
      user: UserModel.fromJson(user is Map<String, Object?> ? user : const {}),
    );
  }

  final String accessToken;
  final String refreshToken;
  final UserModel user;
}
