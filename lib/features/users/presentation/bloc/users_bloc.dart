import 'dart:async';

import 'package:chat_app/core/network/network_info.dart';
import 'package:chat_app/core/usecase/usecase.dart';
import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/users/domain/usecases/get_cached_users.dart';
import 'package:chat_app/features/users/domain/usecases/refresh_users.dart';
import 'package:chat_app/features/users/domain/usecases/watch_users.dart';
import 'package:chat_app/features/users/presentation/bloc/users_event.dart';
import 'package:chat_app/features/users/presentation/bloc/users_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersBloc({
    required WatchUsers watchUsers,
    required RefreshUsers refreshUsers,
    required GetCachedUsers getCachedUsers,
    required NetworkInfo networkInfo,
  }) : _watchUsers = watchUsers,
       _refreshUsers = refreshUsers,
       _getCachedUsers = getCachedUsers,
       _networkInfo = networkInfo,
       super(const UsersInitial()) {
    on<UsersStarted>(_onStarted);
    on<UsersRefreshed>(_onRefreshed);
    on<UsersSearchChanged>(_onSearchChanged);
    on<UsersUpdated>(_onUpdated);
    on<UsersWatchFailed>(_onWatchFailed);
    on<UsersConnectionChanged>(_onConnectionChanged);
  }

  final WatchUsers _watchUsers;
  final RefreshUsers _refreshUsers;
  final GetCachedUsers _getCachedUsers;
  final NetworkInfo _networkInfo;

  String _currentUserId = '';
  StreamSubscription<List<UserEntity>>? _usersSubscription;
  StreamSubscription<bool>? _connectivitySubscription;

  Future<void> _onStarted(UsersStarted event, Emitter<UsersState> emit) async {
    _currentUserId = event.currentUserId;
    emit(const UsersLoading());

    final online = await _networkInfo.isConnected;
    final cached = await _getCachedUsers(const NoParams());
    final cachedUsers = cached.fold<List<UserEntity>>(
      (_) => [],
      (users) => _prepare(users),
    );

    if (cachedUsers.isNotEmpty) {
      emit(UsersLoaded(users: cachedUsers, isOffline: !online));
    } else if (!online) {
      emit(const UsersDisconnected());
    }

    await _usersSubscription?.cancel();
    _usersSubscription = _watchUsers().listen(
      (users) => add(UsersUpdated(users)),
      onError: (error) => add(UsersWatchFailed(error.toString())),
    );

    await _connectivitySubscription?.cancel();
    _connectivitySubscription = _networkInfo.onConnectivityChanged.listen((
      connected,
    ) {
      add(UsersConnectionChanged(connected));
    });
  }

  Future<void> _onRefreshed(
    UsersRefreshed event,
    Emitter<UsersState> emit,
  ) async {
    final current = state;
    if (current is UsersLoaded) {
      emit(current.copyWith(isRefreshing: true));
    } else {
      emit(const UsersLoading());
    }

    final online = await _networkInfo.isConnected;
    if (!online) {
      if (current is UsersLoaded) {
        emit(current.copyWith(isOffline: true, isRefreshing: false));
      } else {
        emit(const UsersDisconnected());
      }
      return;
    }

    final result = await _refreshUsers(const NoParams());
    result.fold(
      (_) {
        if (current is UsersLoaded) {
          emit(current.copyWith(isRefreshing: false, isOffline: false));
        } else {
          emit(const UsersDisconnected());
        }
      },
      (users) {
        emit(
          UsersLoaded(
            users: _prepare(users),
            searchQuery: current is UsersLoaded ? current.searchQuery : '',
            isRefreshing: false,
          ),
        );
      },
    );
  }

  void _onSearchChanged(UsersSearchChanged event, Emitter<UsersState> emit) {
    final current = state;
    if (current is UsersLoaded) {
      emit(current.copyWith(searchQuery: event.query));
    }
  }

  void _onUpdated(UsersUpdated event, Emitter<UsersState> emit) {
    final current = state;
    emit(
      UsersLoaded(
        users: _prepare(event.users),
        searchQuery: current is UsersLoaded ? current.searchQuery : '',
      ),
    );
  }

  void _onWatchFailed(UsersWatchFailed event, Emitter<UsersState> emit) {
    final current = state;
    if (current is UsersLoaded) {
      emit(current.copyWith(isOffline: true, isRefreshing: false));
    } else {
      emit(const UsersDisconnected());
    }
  }

  void _onConnectionChanged(
    UsersConnectionChanged event,
    Emitter<UsersState> emit,
  ) {
    if (event.isConnected) {
      add(const UsersRefreshed());
      return;
    }
    final current = state;
    if (current is UsersLoaded) {
      emit(current.copyWith(isOffline: true));
    } else {
      emit(const UsersDisconnected());
    }
  }

  List<UserEntity> _prepare(List<UserEntity> users) {
    final others = users.where((user) => user.id != _currentUserId).toList();
    others.sort((a, b) {
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return others;
  }

  @override
  Future<void> close() {
    _usersSubscription?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
