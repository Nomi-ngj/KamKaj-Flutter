import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/core/errors/error_mapper.dart';
import 'package:kamkaj_pro/core/errors/failure.dart';
import 'package:kamkaj_pro/core/exceptions/app_exception.dart';

void main() {
  test('maps data exceptions to user-safe failures', () {
    expect(ErrorMapper.map(const NetworkException()), isA<NetworkFailure>());
    expect(ErrorMapper.map(const RequestTimeoutException()), isA<TimeoutFailure>());
    expect(ErrorMapper.map(const UnauthorizedException()), isA<UnauthorizedFailure>());
    expect(ErrorMapper.map(const NotFoundException()), isA<NotFoundFailure>());
    expect(ErrorMapper.map(StateError('boom')), isA<UnexpectedFailure>());
  });

  test('uses the server message when the API provides one', () {
    final failure = ErrorMapper.map(
      const ServerException('HTTP 400', statusCode: 400, serverMessage: 'Incorrect email or password.'),
    );
    expect(failure, isA<ServerFailure>());
    expect(failure.message, 'Incorrect email or password.');
    expect((failure as ServerFailure).statusCode, 400);
  });

  test('never exposes technical details', () {
    final failure = ErrorMapper.map(const ServerException('SQL syntax error near SELECT'));
    expect(failure.message, isNot(contains('SQL')));
  });

  test('guard wraps values and errors in Result', () async {
    final ok = await ErrorMapper.guard(() async => 42);
    expect(ok.valueOrNull, 42);

    final failed = await ErrorMapper.guard<int>(() async => throw const NetworkException());
    expect(failed.isSuccess, isFalse);
    expect(failed.failureOrNull, isA<NetworkFailure>());
  });
}
