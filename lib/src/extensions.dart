import 'package:dollar/dollar.dart';

R Function(A, B, C, D, E, F) $bind6<R, A, B, C, D, E, F>(
    R func(A a, B b, C c, D d, E e, F f),
    [$EffectHandler handler]) {
  final inner =
      $bind7((A a, B b, C c, D d, E e, F f, void g) => func(a, b, c, d, e, f));
  return (a, b, c, d, e, f) => inner(a, b, c, d, e, f, null);
}

R Function(A, B, C, D, E) $bind5<R, A, B, C, D, E>(
    R func(A a, B b, C c, D d, E e),
    [$EffectHandler handler]) {
  final inner = $bind7(
      (A a, B b, C c, D d, E e, void f, void g) => func(a, b, c, d, e),
      handler);
  return (a, b, c, d, e) => inner(a, b, c, d, e, null, null);
}

R Function(A, B, C, D) $bind4<R, A, B, C, D>(R func(A a, B b, C c, D d),
    [$EffectHandler handler]) {
  final inner = $bind7(
      (A a, B b, C c, D d, void e, void f, void g) => func(a, b, c, d),
      handler);
  return (a, b, c, d) => inner(a, b, c, d, null, null, null);
}

R Function(A, B, C) $bind3<R, A, B, C>(R func(A a, B b, C c),
    [$EffectHandler handler]) {
  final inner = $bind7(
      (A a, B b, C c, void d, void e, void f, void g) => func(a, b, c),
      handler);
  return (a, b, c) => inner(a, b, c, null, null, null, null);
}

R Function(A, B) $bind2<R, A, B>(R func(A a, B b), [$EffectHandler handler]) {
  final inner = $bind7(
      (A a, B b, void c, void d, void e, void f, void g) => func(a, b),
      handler);
  return (a, b) => inner(a, b, null, null, null, null, null);
}

R Function(A) $bind<R, A>(R func(A a), [$EffectHandler handler]) {
  final inner = $bind7(
      (A a, void b, void c, void d, void e, void f, void g) => func(a),
      handler);
  return (a) => inner(a, null, null, null, null, null, null);
}

$Ref<T> $ref<T>(T value) {
  final cursor = $cursor<_$RefImpl<T>>(() => _$RefImpl(value));
  cursor.value.value = value;
  return cursor.value;
}

$Var<T> $var<T>(T init()) {
  final didInit = $cursor(() => false);
  final cursor = $cursor<$Var<T>>(() => null);
  $if(!didInit.value, () {
    cursor.value = _$VarImpl(
      init(),
      $bind2((T from,T to) => $effect((cursor) => $UpdateVar(from, to, cursor))),
    );
    didInit.value = true;
  });
  return cursor.value;
}

T $cache<T>(T compute(), bool reusable) {
  final didInit = $cursor(() => false);
  final cursor = $cursor<T>(() => null);
  $if(!didInit.value || !reusable, () {
    cursor.value = compute();
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

bool $updated(Object value) {
  return value != $prev(value);
}

R $diff<T, R>(T value, R diff(T prev, T curr)) {
  return diff($prev(value), value);
}

T $scan<T>(T compute(T prev)) {
  final cursor = $cursor<T>(() => null);
  cursor.value = compute(cursor.value);
  return cursor.value;
}

void $fork(Function() work()) {
  final cleanup = $cursor<Function()>(() => null);

  final maybeCleanup = () => $if(cleanup.value != null, cleanup.value);
  maybeCleanup();
  cleanup.value = work();
  $listen(($End _) => maybeCleanup());
}

void $listen<T>(void callback(T event)) {
  final latestCallback = $ref(callback);
  final listener = $bind((T event) => latestCallback.value(event));
  $effect((cursor) => $AddListener(listener, cursor));
}

abstract class $Ref<T> {
  T get value;
}

class _$RefImpl<T> extends $Ref<T> {
  T value;

  _$RefImpl(this.value);
}

abstract class $Var<T> {
  T get value;
  set value(T newValue);

  T get() => value;
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
  final  Function(T from, T to) onUpdate;

  _$VarImpl(T value, this.onUpdate) : _value = value;
}

class $UpdateVar<T> extends $Effect {
  final $Cursor at;
  final T from;
  final T to;

  @override
  bool operator ==(other) {
    return other is $UpdateVar<T> &&
        other.runtimeType == runtimeType &&
        other.at == at;
  }

  @override
  int get hashCode => at.hashCode;

  $UpdateVar(this.from, this.to, this.at);
}

class $AddListener<T> extends $Effect {
  final $Cursor at;
  final Function callback;
  final Type type;

  @override
  bool operator ==(other) {
    return other is $AddListener<T> &&
        other.runtimeType == runtimeType &&
        other.callback == callback;
  }

  @override
  int get hashCode => runtimeType.hashCode ^ callback.hashCode;

  $AddListener(Function(T) callback, this.at)
      : callback = callback,
        type = T;
}

class $End {}
