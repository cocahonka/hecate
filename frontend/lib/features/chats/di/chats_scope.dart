import 'package:hecate/features/app/di/app_scope.dart';
import 'package:hecate/features/chats/data/api/chats/chats_api.dart';
import 'package:hecate/features/chats/data/api/chats/chats_api_paths.dart';
import 'package:hecate/features/chats/data/api/messages/messages_api.dart';
import 'package:hecate/features/chats/data/api/messages/messages_api_paths.dart';
import 'package:hecate/features/chats/data/api/users/users_api.dart';
import 'package:hecate/features/chats/data/api/users/users_api_paths.dart';
import 'package:hecate/features/chats/data/repository/chats_repository.dart';
import 'package:hecate/features/chats/domain/chats_interactor.dart';
import 'package:hecate/features/chats/domain/chats_state.dart';
import 'package:hecate/features/chats/domain/chats_state_manager.dart';
import 'package:yx_scope/yx_scope.dart';
import 'package:yx_state/yx_state.dart';

abstract interface class ChatsScope implements Scope {
  StateReadable<ChatsState> get stateReadable;

  ChatsInteractor get interactor;
}

final class ChatsScopeContainer extends ChildScopeContainer<AppScope>
    implements ChatsScope {
  ChatsScopeContainer({
    required super.parent,
  });

  @override
  List<Set<AsyncDep<Object>>> get initializeQueue => [
    {
      stateManagerDep,
    },
    {
      interactorDep,
    },
  ];

  // API paths
  late final _chatsApiPathsDep = dep<ChatsApiPaths>(
    () => ChatsApiPathsImpl(),
  );

  late final _messagesApiPathsDep = dep<MessagesApiPaths>(
    () => MessagesApiPathsImpl(),
  );

  late final _usersApiPathsDep = dep<UsersApiPaths>(
    () => UsersApiPathsImpl(),
  );

  // APIs
  late final _chatsApiDep = dep<ChatsApi>(
    () => ChatsApiImpl(
      dio: parent.dio,
      paths: _chatsApiPathsDep.get,
    ),
  );

  late final _messagesApiDep = dep<MessagesApi>(
    () => MessagesApiImpl(
      dio: parent.dio,
      paths: _messagesApiPathsDep.get,
    ),
  );

  late final _usersApiDep = dep<UsersApi>(
    () => UsersApiImpl(
      dio: parent.dio,
      paths: _usersApiPathsDep.get,
    ),
  );

  // Repository
  late final _repositoryDep = dep<ChatsRepository>(
    () => ChatsRepositoryImpl(
      chatsApi: _chatsApiDep.get,
      messagesApi: _messagesApiDep.get,
      usersApi: _usersApiDep.get,
    ),
  );

  // State manager
  late final stateManagerDep = asyncDep<ChatsStateManager>(
    () => ChatsStateManagerImpl(),
  );

  // Interactor
  late final interactorDep = asyncDep<ChatsInteractor>(
    () => ChatsInteractorImpl(
      repository: _repositoryDep.get,
      stateManager: stateManagerDep.get,
      bindingsInteractor: parent.bindings.interactor,
      appNavigationManager: parent.navigation.manager,
      authStateManager: parent.auth.stateManager,
    ),
  );

  @override
  StateReadable<ChatsState> get stateReadable => stateManagerDep.get;

  @override
  ChatsInteractor get interactor => interactorDep.get;
}

final class ChatsScopeHolder
    extends BaseChildScopeHolder<ChatsScope, ChatsScopeContainer, AppScope> {
  ChatsScopeHolder(AppScope parent) : super(parent);

  @override
  ChatsScopeContainer createContainer(AppScope parent) =>
      ChatsScopeContainer(parent: parent);
}
