import 'dart:async';

import 'package:chat_app/core/network/network_info.dart';
import 'package:chat_app/core/usecase/usecase.dart';
import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_in.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_out.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_up.dart';
import 'package:chat_app/features/auth/domain/usecases/watch_auth.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:chat_app/features/users/domain/usecases/ensure_user_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignIn signIn,
    required SignUp signUp,
    required SignOut signOut,
    required WatchAuth watchAuth,
    required EnsureUserProfile ensureUserProfile,
    required NetworkInfo networkInfo,
  }) : _signIn = signIn,
       _signUp = signUp,
       _signOut = signOut,
       _watchAuth = watchAuth,
       _ensureUserProfile = ensureUserProfile,
       _networkInfo = networkInfo,
       super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthProfileUpdated>(_onProfileUpdated);
  }

  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;
  final WatchAuth _watchAuth;
  final EnsureUserProfile _ensureUserProfile;
  final NetworkInfo _networkInfo;

  StreamSubscription<UserEntity?>? _authSubscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _authSubscription?.cancel();
    _authSubscription = _watchAuth().listen((user) {
      add(AuthUserChanged(user));
    });
  }

  Future<void> _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    if (user != null) {
      final result = await _ensureUserProfile(user);
      result.fold((failure) {
        if (kDebugMode) {
          debugPrint('Failed to save user profile: ${failure.message}');
        }
      }, (_) {});
      emit(Authenticated(user));
      return;
    }
    if (state is AuthLoading) {
      return;
    }
    if (state is AuthInitial || state is Authenticated) {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    if (!await _networkInfo.isConnected) {
      emit(const Unauthenticated(message: 'No internet connection.'));
      return;
    }
    final result = await _signIn(
      SignInParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(Unauthenticated(message: failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    if (!await _networkInfo.isConnected) {
      emit(const Unauthenticated(message: 'No internet connection.'));
      return;
    }
    final result = await _signUp(
      SignUpParams(
        displayName: event.displayName,
        email: event.email,
        password: event.password,
      ),
    );
    result.fold(
      (failure) => emit(Unauthenticated(message: failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  void _onProfileUpdated(
    AuthProfileUpdated event,
    Emitter<AuthState> emit,
  ) {
    if (state is Authenticated) {
      emit(Authenticated(event.user));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final previous = state;
    final result = await _signOut(const NoParams());
    result.fold(
      (failure) {
        if (previous is Authenticated) {
          emit(previous);
        } else {
          emit(Unauthenticated(message: failure.message));
        }
      },
      (_) => emit(const Unauthenticated()),
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
