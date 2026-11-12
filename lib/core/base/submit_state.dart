import 'package:equatable/equatable.dart';

import '../errors/failure.dart';

enum SubmitStatus { idle, submitting, success, failure }

/// Immutable state for form / action screens (sign in, save address …).
final class SubmitState extends Equatable {
  const SubmitState({this.status = SubmitStatus.idle, this.failure});

  const SubmitState.idle() : this();
  const SubmitState.submitting() : this(status: SubmitStatus.submitting);
  const SubmitState.success() : this(status: SubmitStatus.success);
  const SubmitState.failed(Failure failure) : this(status: SubmitStatus.failure, failure: failure);

  final SubmitStatus status;
  final Failure? failure;

  bool get isSubmitting => status == SubmitStatus.submitting;
  bool get isSuccess => status == SubmitStatus.success;
  String? get errorMessage => failure?.message;

  @override
  List<Object?> get props => [status, failure];
}
