import 'dart:async';

import 'package:chat_app/core/constants/app_timeouts.dart';
import 'package:chat_app/core/network/network_info.dart';
import 'package:chat_app/core/usecase/usecase.dart';
import 'package:chat_app/features/auth/domain/entities/user_entity.dart';
import 'package:chat_app/features/chat/domain/entities/chat_preview_entity.dart';
import 'package:chat_app/features/chat/domain/usecases/get_cached_chat_previews.dart';
import 'package:chat_app/features/chat/domain/usecases/refresh_chat_previews.dart';
import 'package:chat_app/features/chat/domain/usecases/watch_chat_previews.dart';
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
    required WatchChatPreviews watchChatPreviews,
    required RefreshChatPreviews refreshChatPreviews,
    required GetCachedChatPreviews getCachedChatPreviews,
    required NetworkInfo networkInfo,
  }) : _watchUsers = watchUsers,
       _refreshUsers = refreshUsers,
       _getCachedUsers = getCachedUsers,
       _watchChatPreviews = watchChatPreviews,
       _refreshChatPreviews = refreshChatPreviews,
       _getCachedChatPreviews = getCachedChatPreviews,
       _networkInfo = networkInfo,
       super(const UsersInitial()) {
    on<UsersStarted>(_onStarted);
    on<UsersRefreshed>(_onRefreshed);
    on<UsersSearchChanged>(_onSearchChanged);
    on<UsersUpdated>(_onUpdated);
    on<UsersPreviewsUpdated>(_onPreviewsUpdated);
    on<UsersWatchFailed>(_onWatchFailed);
    on<UsersFirstSnapshotTimedOut>(_onFirstSnapshotTimedOut);
    on<UsersConnectionChanged>(_onConnectionChanged);
  }

  final WatchUsers _watchUsers;
  final RefreshUsers _refreshUsers;
  final GetCachedUsers _getCachedUsers;
  final WatchChatPreviews _watchChatPreviews;
  final RefreshChatPreviews _refreshChatPreviews;
  final GetCachedChatPreviews _getCachedChatPreviews;
  final NetworkInfo _networkInfo;

  String _currentUserId = '';
  Map<String, ChatPreviewEntity> _previews = {};
  StreamSubscription<List<UserEntity>>? _usersSubscription;
  StreamSubscription<List<ChatPreviewEntity>>? _previewsSubscription;
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _firstSnapshotTimer;

  Future<void> _onStarted(UsersStarted event, Emitter<UsersState> emit) async {
    _currentUserId = event.currentUserId;
    emit(const UsersLoading());

    final online = await _networkInfo.isConnected;
    final cached = await _getCachedUsers(const NoParams());
    final cachedUsers = cached.fold<List<UserEntity>>(
      (_) => [],
      (users) => users,
    );
    final cachedPreviews = await _getCachedChatPreviews(_currentUserId);
    _previews = cachedPreviews.fold<Map<String, ChatPreviewEntity>>(
      (_) => {},
      _toMap,
    );

    if (cachedUsers.isNotEmpty) {
      emit(
        UsersLoaded(
          users: _prepare(cachedUsers),
          currentUserId: _currentUserId,
          previews: _previews,
          isOffline: !online,
        ),
      );
    } else if (!online) {
      emit(const UsersDisconnected());
    }

    await _listenToUsers();
    await _listenToConnectivity();
    _armFirstSnapshotTimer();
  }

  Future<void> _listenToUsers() async {
    await _usersSubscription?.cancel();
    _usersSubscription = _watchUsers().listen(
      (users) => add(UsersUpdated(users)),
      onError: (error) => add(UsersWatchFailed(error.toString())),
    );

    await _previewsSubscription?.cancel();
    _previewsSubscription = _watchChatPreviews(_currentUserId).listen(
      (previews) => add(UsersPreviewsUpdated(previews)),
      onError: (_) {},
    );
  }

  Future<void> _listenToConnectivity() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = _networkInfo.onConnectivityChanged.listen((
      connected,
    ) {
      add(UsersConnectionChanged(connected));
    });
  }

  void _armFirstSnapshotTimer() {
    _firstSnapshotTimer?.cancel();
    if (state is! UsersLoading) {
      return;
    }
    _firstSnapshotTimer = Timer(AppTimeouts.firstSnapshot, () {
      add(const UsersFirstSnapshotTimedOut());
    });
  }

  void _cancelFirstSnapshotTimer() {
    _firstSnapshotTimer?.cancel();
    _firstSnapshotTimer = null;
  }

  Future<void> _onRefreshed(
    UsersRefreshed event,
    Emitter<UsersState> emit,
  ) async {
    final current = state;
    if (current is UsersLoaded) {
      emit(current.copyWith(isRefreshing: true, clearRefreshError: true));
    } else {
      emit(const UsersLoading());
      _armFirstSnapshotTimer();
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

    final usersResult = await _refreshUsers(const NoParams());
    final usersError = usersResult.fold((failure) => failure.message, (_) => null);
    if (usersError != null) {
      if (current is UsersLoaded) {
        emit(
          current.copyWith(
            isRefreshing: false,
            isOffline: false,
            refreshError: usersError,
          ),
        );
      } else {
        emit(UsersFailure(usersError));
      }
      return;
    }

    final users = usersResult.getOrElse(() => <UserEntity>[]);
    final previewsResult = await _refreshChatPreviews(_currentUserId);
    previewsResult.fold((_) {}, (fresh) {
      _previews = _toMap(fresh);
    });

    _cancelFirstSnapshotTimer();
    emit(
      UsersLoaded(
        users: _prepare(users),
        currentUserId: _currentUserId,
        previews: _previews,
        searchQuery: current is UsersLoaded ? current.searchQuery : '',
        isRefreshing: false,
        isOffline: false,
      ),
    );
  }

  void _onSearchChanged(UsersSearchChanged event, Emitter<UsersState> emit) {
    final current = state;
    if (current is UsersLoaded) {
      emit(current.copyWith(searchQuery: event.query));
    }
  }

  void _onUpdated(UsersUpdated event, Emitter<UsersState> emit) {
    _cancelFirstSnapshotTimer();
    final current = state;
    emit(
      UsersLoaded(
        users: _prepare(event.users),
        currentUserId: _currentUserId,
        previews: _previews,
        searchQuery: current is UsersLoaded ? current.searchQuery : '',
        isOffline: current is UsersLoaded ? current.isOffline : false,
      ),
    );
  }

  void _onPreviewsUpdated(
    UsersPreviewsUpdated event,
    Emitter<UsersState> emit,
  ) {
    _previews = _toMap(event.previews);
    final current = state;
    if (current is! UsersLoaded) {
      return;
    }
    emit(
      current.copyWith(
        users: _prepare(current.users),
        previews: _previews,
      ),
    );
  }

  Future<void> _onWatchFailed(
    UsersWatchFailed event,
    Emitter<UsersState> emit,
  ) async {
    final current = state;
    final online = await _networkInfo.isConnected;
    if (current is UsersLoaded) {
      emit(current.copyWith(isOffline: !online, isRefreshing: false));
      return;
    }
    if (!online) {
      emit(const UsersDisconnected());
      return;
    }
    emit(UsersFailure(event.message));
  }

  Future<void> _onFirstSnapshotTimedOut(
    UsersFirstSnapshotTimedOut event,
    Emitter<UsersState> emit,
  ) async {
    if (state is! UsersLoading) {
      return;
    }
    final online = await _networkInfo.isConnected;
    if (!online) {
      emit(const UsersDisconnected());
      return;
    }
    emit(const UsersFailure('Request timed out. Please try again.'));
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
    others.sort(_compareUsers);
    return others;
  }

  int _compareUsers(UserEntity a, UserEntity b) {
    final timeA = _previews[a.id]?.lastMessageTime;
    final timeB = _previews[b.id]?.lastMessageTime;
    if (timeA != null && timeB != null) {
      final byTime = timeB.compareTo(timeA);
      if (byTime != 0) {
        return byTime;
      }
    } else if (timeA != null) {
      return -1;
    } else if (timeB != null) {
      return 1;
    }
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  }

  Map<String, ChatPreviewEntity> _toMap(List<ChatPreviewEntity> previews) {
    return {
      for (final preview in previews)
        if (preview.peerId.isNotEmpty) preview.peerId: preview,
    };
  }

  @override
  Future<void> close() {
    _cancelFirstSnapshotTimer();
    _usersSubscription?.cancel();
    _previewsSubscription?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
