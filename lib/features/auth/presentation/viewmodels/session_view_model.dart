import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/injection.dart';
import '../../domain/entities/user.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

final class SessionState extends Equatable {
  const SessionState({this.status = SessionStatus.unknown, this.user});

  final SessionStatus status;
  final User? user;

  bool get isAuthenticated => status == SessionStatus.authenticated;

  @override
  List<Object?> get props => [status, user];
}

/// App-wide authentication state. The router listens to it for guards.
final class SessionViewModel extends Notifier<SessionState> {
  @override
  SessionState build() {
    final subscription = ref.read(sessionEventsProvider).expired.listen((_) => expire());
    ref.onDispose(subscription.cancel);
    return const SessionState();
  }

  Future<void> restore() async {
    final result = await ref.read(getCurrentUserProvider).call();
    final user = result.valueOrNull;
    state = user == null
        ? const SessionState(status: SessionStatus.unauthenticated)
        : SessionState(status: SessionStatus.authenticated, user: user);
  }

  void signedIn(User user) {
    state = SessionState(status: SessionStatus.authenticated, user: user);
  }

  Future<void> signOut() async {
    await ref.read(signOutProvider).call();
    state = const SessionState(status: SessionStatus.unauthenticated);
  }

  /// Called by the network layer when token refresh fails.
  void expire() {
    if (state.status == SessionStatus.unauthenticated) return;
    state = const SessionState(status: SessionStatus.unauthenticated);
  }
}

final sessionProvider = NotifierProvider<SessionViewModel, SessionState>(SessionViewModel.new);
