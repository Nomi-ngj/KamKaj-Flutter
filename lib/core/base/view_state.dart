import 'package:equatable/equatable.dart';

import '../errors/failure.dart';

/// Generic immutable state for screens that load one piece of data.
///
/// `initial → loading → (success | empty | failure)`; `refreshing` keeps the
/// last data visible while reloading.
sealed class ViewState<T> extends Equatable {
  const ViewState();

  bool get isLoading => this is ViewLoading<T>;
  T? get dataOrNull => switch (this) {
        ViewSuccess<T>(:final data) => data,
        ViewRefreshing<T>(:final data) => data,
        _ => null,
      };
}

final class ViewInitial<T> extends ViewState<T> {
  const ViewInitial();

  @override
  List<Object?> get props => const [];
}

final class ViewLoading<T> extends ViewState<T> {
  const ViewLoading();

  @override
  List<Object?> get props => const [];
}

final class ViewSuccess<T> extends ViewState<T> {
  const ViewSuccess(this.data);
  final T data;

  @override
  List<Object?> get props => [data];
}

final class ViewRefreshing<T> extends ViewState<T> {
  const ViewRefreshing(this.data);
  final T data;

  @override
  List<Object?> get props => [data];
}

final class ViewEmpty<T> extends ViewState<T> {
  const ViewEmpty();

  @override
  List<Object?> get props => const [];
}

final class ViewFailure<T> extends ViewState<T> {
  const ViewFailure(this.failure);
  final Failure failure;

  bool get isOffline => failure is NetworkFailure;
  bool get isUnauthorized => failure is UnauthorizedFailure;

  @override
  List<Object?> get props => [failure];
}
