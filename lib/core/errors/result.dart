import 'failure.dart';

/// Either a [Success] value or a [Failure]. Returned by repositories and
/// use cases so errors are part of the type, not hidden exceptions.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = Failed<T>;

  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) {
    final self = this;
    return switch (self) {
      Success<T>(:final value) => success(value),
      Failed<T>(failure: final f) => failure(f),
    };
  }

  bool get isSuccess => this is Success<T>;

  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Failed<T>() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Failed<T>(failure: final f) => f,
      };
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failed<T> extends Result<T> {
  const Failed(this.failure);
  final Failure failure;
}
