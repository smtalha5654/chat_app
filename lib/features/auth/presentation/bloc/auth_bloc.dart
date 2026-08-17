import 'dart:async';

import 'package:chat_app/core/usecase/usecase.dart';
import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_in.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_out.dart';
import 'package:chat_app/features/auth/domain/usecases/sign_up.dart';
import 'package:chat_app/features/auth/domain/usecases/watch_auth.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:chat_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignIn signIn,
    required SignUp signUp,
    required SignOut signOut,
    required WatchAuth watchAuth,
  }) : _signIn = signIn,
       _signUp = signUp,
       _signOut = signOut,
       _watchAuth = watchAuth,
       super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
  }

  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;
  final WatchAuth _watchAuth;

  StreamSubscription<UserEntity?>? _authSubscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _authSubscription?.cancel();
    _authSubscription = _watchAuth().listen((user) {
      add(AuthUserChanged(user));
    });
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user != null) {
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
