import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hecate/features/app/navigation/app_pages.dart';

typedef AppNavigationState = List<AppPage>;
typedef AppNavigationGuard =
    AppNavigationState Function(BuildContext context, AppNavigationState state);

class AppNavigator extends StatefulWidget {
  AppNavigator({
    required this.pages,
    this.guards = const [],
    this.observers = const [],
    this.transitionDelegate = const DefaultTransitionDelegate<Object?>(),
    this.revalidate,
    this.onBackButtonPressed,
    super.key,
  }) : assert(pages.isNotEmpty, 'pages cannot be empty'),
       controller = null;

  AppNavigator.controlled({
    required ValueNotifier<AppNavigationState> this.controller,
    this.guards = const [],
    this.observers = const [],
    this.transitionDelegate = const DefaultTransitionDelegate<Object?>(),
    this.revalidate,
    this.onBackButtonPressed,
    super.key,
  }) : assert(controller.value.isNotEmpty, 'controller cannot be empty'),
       pages = controller.value;

  static AppNavigatorState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<AppNavigatorState>();

  static AppNavigationState? stateOf(BuildContext context) =>
      maybeOf(context)?.state;

  static NavigatorState? navigatorOf(BuildContext context) =>
      maybeOf(context)?.navigator;

  static void change(
    BuildContext context,
    AppNavigationState Function(AppNavigationState pages) fn,
  ) => maybeOf(context)?.change(fn);

  static void push(BuildContext context, AppPage page) =>
      change(context, (state) => [...state, page]);

  static void pop(BuildContext context) => change(context, (state) {
    if (state.isNotEmpty) state.removeLast();
    return state;
  });

  static void reset(BuildContext context, AppPage page) {
    final navigator = maybeOf(context);
    if (navigator == null) return;
    navigator.change((_) => navigator.widget.pages);
  }

  final AppNavigationState pages;

  final ValueNotifier<AppNavigationState>? controller;

  final List<AppNavigationGuard> guards;

  final List<NavigatorObserver> observers;

  final TransitionDelegate<Object?> transitionDelegate;

  final Listenable? revalidate;

  final ({AppNavigationState state, bool handled}) Function(
    AppNavigationState state,
  )?
  onBackButtonPressed;

  @override
  State<AppNavigator> createState() => AppNavigatorState();
}

class AppNavigatorState extends State<AppNavigator>
    with WidgetsBindingObserver {
  NavigatorState? get navigator => _observer.navigator;
  final NavigatorObserver _observer = NavigatorObserver();

  AppNavigationState get state => _state;

  late AppNavigationState _state;
  List<NavigatorObserver> _observers = const [];

  @override
  void initState() {
    super.initState();
    _state = widget.pages;
    widget.revalidate?.addListener(revalidate);
    _observers = <NavigatorObserver>[_observer, ...widget.observers];
    widget.controller?.addListener(_controllerListener);
    _controllerListener();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    revalidate();
  }

  @override
  void didUpdateWidget(covariant AppNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.revalidate, oldWidget.revalidate)) {
      oldWidget.revalidate?.removeListener(revalidate);
      widget.revalidate?.addListener(revalidate);
    }
    if (!identical(widget.observers, oldWidget.observers)) {
      _observers = <NavigatorObserver>[_observer, ...widget.observers];
    }
    if (!identical(widget.controller, oldWidget.controller)) {
      oldWidget.controller?.removeListener(_controllerListener);
      widget.controller?.addListener(_controllerListener);
      _controllerListener();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller?.removeListener(_controllerListener);
    widget.revalidate?.removeListener(revalidate);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() {
    final backButtonHandler = widget.onBackButtonPressed;
    if (backButtonHandler != null) {
      final result = backButtonHandler(_state.toList());
      change((pages) => result.state);
      return SynchronousFuture(result.handled);
    }

    if (_state.length < 2) return SynchronousFuture(false);
    _onDidRemovePage(_state.last);
    return SynchronousFuture(true);
  }

  void _setStateToController() {
    if (widget.controller
        case final ValueNotifier<AppNavigationState> controller) {
      controller
        ..removeListener(_controllerListener)
        ..value = _state
        ..addListener(_controllerListener);
    }
  }

  void _controllerListener() {
    final controller = widget.controller;
    if (controller == null || !mounted) return;
    final newValue = controller.value;
    if (identical(newValue, _state)) return;
    final ctx = context;
    final next = widget.guards.fold(newValue.toList(), (s, g) => g(ctx, s));
    if (next.isEmpty || listEquals(next, _state)) {
      _setStateToController();
    } else {
      _state = UnmodifiableListView<AppPage>(next);
      _setStateToController();
      setState(() {});
    }
  }

  void revalidate() {
    if (!mounted) return;
    final ctx = context;
    final next = widget.guards.fold(_state.toList(), (s, g) => g(ctx, s));
    if (next.isEmpty || listEquals(next, _state)) return;
    _state = UnmodifiableListView<AppPage>(next);
    _setStateToController();
    setState(() {});
  }

  void change(AppNavigationState Function(AppNavigationState pages) fn) {
    final prev = _state.toList();
    var next = fn(prev);
    if (next.isEmpty) return;
    if (!mounted) return;
    final ctx = context;
    next = widget.guards.fold(next, (s, g) => g(ctx, s));
    if (next.isEmpty || listEquals(next, _state)) return;
    _state = UnmodifiableListView<AppPage>(next);
    _setStateToController();
    setState(() {});
  }

  void _onDidRemovePage(Page<Object?> page) {
    change((pages) => pages..removeWhere((p) => p.key == page.key));
  }

  @override
  Widget build(BuildContext context) => Navigator(
    pages: _state,
    reportsRouteUpdateToEngine: false,
    transitionDelegate: widget.transitionDelegate,
    onDidRemovePage: _onDidRemovePage,
    observers: _observers,
  );
}
