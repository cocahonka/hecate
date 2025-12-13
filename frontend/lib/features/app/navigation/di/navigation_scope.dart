import 'package:hecate/features/app/navigation/app_navigation_manager.dart';
import 'package:hecate/features/app/navigation/app_navigation_revalidator.dart';
import 'package:yx_scope/yx_scope.dart';

abstract interface class NavigationScope {
  AppNavigationManager get manager;

  AppNavigationRevalidator get revalidator;
}

abstract interface class NavigationParentScope extends ScopeContainer {}

final class NavigationScopeModule<
  ParentScopeContainer extends NavigationParentScope
>
    extends ScopeModule<NavigationParentScope>
    implements NavigationScope {
  NavigationScopeModule(super.container);

  late final managerDep = asyncDep<AppNavigationManager>(
    () => AppNavigationManagerImpl(
      revalidator: revalidatorDep.get,
    ),
  );

  late final revalidatorDep = asyncDep<AppNavigationRevalidator>(
    () => AppNavigationRevalidatorImpl(),
  );

  @override
  AppNavigationManager get manager => managerDep.get;

  @override
  AppNavigationRevalidator get revalidator => revalidatorDep.get;
}
