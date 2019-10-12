import 'package:dollar/dollar.dart';

R Function(A, B, C, D) $bind4<R, A, B, C, D>(R func(A a, B b, C c, D d),
    [$EffectHandlerCreator createHandler]) {
  final inner = $bind(
      (A a, B b, C c, D d, void e, void f, void g) => func(a, b, c, d),
      createHandler);
  return (a, b, c, d) => inner(a, b, c, d, null, null, null);
}

extension $Bind4<R, A, B, C, D> on R Function(A, B, C, D) {
  R Function(A, B, C, D) $bind([$EffectHandlerCreator createHandler]) =>
      $bind4(this, createHandler);
}

R Function(A, B, C) $bind3<R, A, B, C>(R func(A a, B b, C c),
    [$EffectHandlerCreator createHandler]) {
  final inner = $bind(
      (A a, B b, C c, void d, void e, void f, void g) => func(a, b, c),
      createHandler);
  return (a, b, c) => inner(a, b, c, null, null, null, null);
}

extension $Bind3<R, A, B, C> on R Function(A, B, C) {
  R Function(A, B, C) $bind([$EffectHandlerCreator createHandler]) =>
      $bind3(this, createHandler);
}

R Function(A, B) $bind2<R, A, B>(R func(A a, B b),
    [$EffectHandlerCreator createHandler]) {
  final inner = $bind(
      (A a, B b, void c, void d, void e, void f, void g) => func(a, b),
      createHandler);
  return (a, b) => inner(a, b, null, null, null, null, null);
}

extension $Bind2<R, A, B> on R Function(A, B) {
  R Function(A, B) $bind([$EffectHandlerCreator createHandler]) =>
      $bind2(this, createHandler);
}

R Function(A) $bind1<R, A>(R func(A a), [$EffectHandlerCreator createHandler]) {
  final inner = $bind(
      (A a, void b, void c, void d, void e, void f, void g) => func(a),
      createHandler);
  return (a) => inner(a, null, null, null, null, null, null);
}

extension $Bind1<R, A> on R Function(A) {
  R Function(A) $bind([$EffectHandlerCreator createHandler]) =>
      $bind1(this, createHandler);
}

R Function() $bind0<R>(R func(), [$EffectHandlerCreator createHandler]) {
  final inner = $bind(
      (void a, void b, void c, void d, void e, void f, void g) => func(),
      createHandler);
  return () => inner(null, null, null, null, null, null, null);
}

extension $Bind0<R> on R Function() {
  R Function() $bind([$EffectHandlerCreator createHandler]) =>
      $bind0(this, createHandler);
}

R $switch<T, R>(T value, Map<T, R Function()> handlers) {
  return $fork(value, handlers[value]);
}

T $if<T>(bool condition, T then(), {T orElse()}) {
  return $fork(condition, () {
    return condition
        ? then != null ? then() : null
        : orElse != null ? orElse() : null;
  });
}

T $unless<T>(bool condition, T run()) {
  return $if(!condition, run);
}

$Ref<T> $ref<T>(T value) {
  final cursor = $cursor<_$RefImpl<T>>(() => _$RefImpl(value));
  cursor.value.value = value;
  return cursor.value;
}

final _ref = $ref;

extension $RefExtension<T> on T {
  $Ref<T> get $ref => _ref(this);
}

$Var<T> $var<T>(T init()) {
  final didInit = $cursor(() => false);
  final cursor = $cursor<$Var<T>>(() => null);
  $if(!didInit.value, () {
    cursor.value = _$VarImpl(
      init(),
      $bind2((T from, T to) => $raise($VarUpdated(from, to, cursor))),
    );
    didInit.value = true;
  });
  return cursor.value;
}

T $cache<T>(T compute(), bool reusable) {
  final didInit = $cursor(() => false);
  final cursor = $cursor<T>(() => null);
  $if(!didInit.value || !reusable, () {
    cursor.value = $bind0(compute, (parent) {
      return (effect) {
        if (effect is $VarUpdated) didInit.value = false;
        parent(effect);
      };
    })();
    didInit.value = true;
  });
  return cursor.value;
}

T $final<T>(T init()) {
  return $cache<T>(() => init(), true);
}

T $prev<T>(T value) {
  final curr = $cursor<T>(() => null);
  final prev = curr.value;
  curr.value = value;
  return prev;
}

final _prev = $prev;

extension $Prev<T> on T {
  T get $prev => _prev(this);
}

T $distinct<T>(T value, [bool equals(T a, T b)]) {
  final curr = $cursor<T>(() => null);
  final shouldUpdate = curr.value == null ||
      !(equals?.call(curr.value, value) ?? curr.value == value);
  if (shouldUpdate) curr.value = value;
  return curr.value;
}

bool $equals<T>(T value) {
  return value == $prev(value);
}

extension $Equals on Object {
  bool get $isEqual => $equals(this);
}

bool $identical<T>(T value) {
  return identical(value, $prev(value));
}

extension $Identical on Object {
  bool get $isIdentical => $identical(this);
}

bool $shallowEquals(Iterable value) {
  return _iterableEquals(value, $prev(value));
}

extension $ShallowEquals on Iterable {
  bool get $isShallowEqual => $shallowEquals(this);
}

T $while<T>(bool condition(), T compute()) {
  compute = $bind0(compute);
  T result;
  for (; $isolate(() => condition());) {
    result = compute();
  }
  return result;
}

R $interpolate<T, R>(T value, R diff(T prev, T curr)) {
  return diff($prev(value), value);
}

R $aggregate<T, R>(T value, R aggregator(R aggreagte, T value)) {
  final cursor = $cursor<R>(() => null);
  cursor.value = aggregator(cursor.value, value);
  return cursor.value;
}

T $generate<T>(T compute(T prev)) {
  final cursor = $cursor<T>(() => null);
  cursor.value = compute(cursor.value);
  return cursor.value;
}

T $memo<T>(T compute(), Iterable deps) {
  return $cache(compute, $shallowEquals(deps));
}

void $async(Function() work()) {
  final cleanup = $cursor<Function()>(() => null);

  final maybeCleanup = () => $if(cleanup.value != null, cleanup.value);
  maybeCleanup();
  cleanup.value = work();
  $listen(($ContextTerminated _) => maybeCleanup());
}

void $effect(Function() effect(), Iterable deps) {
  $memo(() => $async(effect), deps);
}

void $listen<T>(void callback(T event)) {
  final cursor = $cursor(() => null);
  final listener = $bind1(callback);
  $raise($Listened(listener, cursor));
}

void $rollback<T>(T rollback(Object from)) {
  final cursor = $cursor(() => null);
  $raise($Rollback(rollback, cursor));
}

void $commit() {
  $raise($Commit());
}

abstract class $Ref<T> {
  T get value;
  T get() => value;
}

class _$RefImpl<T> extends $Ref<T> {
  T value;

  _$RefImpl(this.value);
}

abstract class $Var<T> extends $Ref<T> {
  set value(T newValue);
  T set(T newValue) => value = newValue;
}

class _$VarImpl<T> extends $Var<T> {
  @override
  T get value => _value;

  @override
  set value(T newValue) {
    final prevValue = _value;
    _value = newValue;
    onUpdate(prevValue, newValue);
  }

  T _value;
  final Function(T from, T to) onUpdate;

  _$VarImpl(T value, this.onUpdate) : _value = value;
}

class $VarUpdated<T> {
  final $Cursor at;
  final T from;
  final T to;

  @override
  bool operator ==(other) {
    return other is $VarUpdated<T> &&
        other.runtimeType == runtimeType &&
        other.at == at;
  }

  @override
  int get hashCode => at.hashCode;

  $VarUpdated(this.from, this.to, this.at);
}

class $Listened<T> {
  final $Cursor at;
  final Function callback;
  final Type type;

  @override
  bool operator ==(other) {
    return other is $Listened<T> &&
        other.runtimeType == runtimeType &&
        other.callback == callback;
  }

  @override
  int get hashCode => runtimeType.hashCode ^ callback.hashCode;

  $Listened(Function(T) callback, this.at)
      : callback = callback,
        type = T;
}

class $ContextTerminated {}

class $Rollback {
  final dynamic Function(Object from) rollback;
  final $Cursor cursor;

  $Rollback(this.rollback, this.cursor);
}

class $Commit {}

$EffectHandlerCreator $onListened($Listeners listeners) {
  return (parent) {
    return (effect) {
      if (effect is $Listened) {
        listeners.add(effect.type, effect.callback, effect.at);
      } else {
        return parent(effect);
      }
    };
  };
}

$EffectHandlerCreator $onVarUpdated(dynamic onUpdate($VarUpdated effect)) {
  return (parent) {
    return (effect) {
      if (effect is $VarUpdated) {
        return onUpdate(effect);
      } else {
        return parent(effect);
      }
    };
  };
}

class $Listeners {
  add(Type eventType, Function callback, $Cursor at) {
    assert(_types[at] == null || _types[at] == eventType);
    _types[at] = eventType;
    (_cursors[eventType] ??= {}).add(at);
    _callbacks[at] = callback;
  }

  trigger<T>(T event) {
    for (final cursor in (_cursors[event.runtimeType] ??= {})) {
      final callback = _callbacks[cursor];
      if (callback is Function) {
        callback(event);
      }
    }
  }

  final _cursors = Map<Type, Set<$Cursor>>();
  final _callbacks = Map<$Cursor, Function>();
  final _types = Map<$Cursor, Type>();
}

// copied from package:collection
bool _iterableEquals<E>(Iterable<E> elements1, Iterable<E> elements2) {
  if (identical(elements1, elements2)) return true;
  if (elements1 == null || elements2 == null) return false;
  var it1 = elements1.iterator;
  var it2 = elements2.iterator;
  while (true) {
    bool hasNext = it1.moveNext();
    if (hasNext != it2.moveNext()) return false;
    if (!hasNext) return true;
    if (it1.current != it2.current) return false;
  }
}
