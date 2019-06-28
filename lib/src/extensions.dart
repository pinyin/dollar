import 'package:dollar/dollar.dart';

R Function(A, B, C, D, E, F) $bind6<R, A, B, C, D, E, F>(
    R func(A a, B b, C c, D d, E e, F f),
    [$EffectHandlerCreator createHandler]) {
  final inner = $bind7(
      (A a, B b, C c, D d, E e, F f, void g) => func(a, b, c, d, e, f),
      createHandler);
  return (a, b, c, d, e, f) => inner(a, b, c, d, e, f, null);
}

R Function(A, B, C, D, E) $bind5<R, A, B, C, D, E>(
    R func(A a, B b, C c, D d, E e),
    [$EffectHandlerCreator createHandler]) {
  final inner = $bind7(
      (A a, B b, C c, D d, E e, void f, void g) => func(a, b, c, d, e),
      createHandler);
  return (a, b, c, d, e) => inner(a, b, c, d, e, null, null);
}

R Function(A, B, C, D) $bind4<R, A, B, C, D>(R func(A a, B b, C c, D d),
    [$EffectHandlerCreator createHandler]) {
  final inner = $bind7(
      (A a, B b, C c, D d, void e, void f, void g) => func(a, b, c, d),
      createHandler);
  return (a, b, c, d) => inner(a, b, c, d, null, null, null);
}

R Function(A, B, C) $bind3<R, A, B, C>(R func(A a, B b, C c),
    [$EffectHandlerCreator createHandler]) {
  final inner = $bind7(
      (A a, B b, C c, void d, void e, void f, void g) => func(a, b, c),
      createHandler);
  return (a, b, c) => inner(a, b, c, null, null, null, null);
}

R Function(A, B) $bind2<R, A, B>(R func(A a, B b),
    [$EffectHandlerCreator createHandler]) {
  final inner = $bind7(
      (A a, B b, void c, void d, void e, void f, void g) => func(a, b),
      createHandler);
  return (a, b) => inner(a, b, null, null, null, null, null);
}

R Function(A) $bind<R, A>(R func(A a), [$EffectHandlerCreator createHandler]) {
  final inner = $bind7(
      (A a, void b, void c, void d, void e, void f, void g) => func(a),
      createHandler);
  return (a) => inner(a, null, null, null, null, null, null);
}

R Function() $bind0<R>(R func(), [$EffectHandlerCreator createHandler]) {
  final inner = $bind7(
      (void a, void b, void c, void d, void e, void f, void g) => func(),
      createHandler);
  return () => inner(null, null, null, null, null, null, null);
}

T $if<T>(bool condition, T then(), {T orElse()}) {
  then = $bind0(then);
  orElse = orElse != null ? $bind0(orElse) : null;

  T result;
  if (condition) {
    result = then();
  } else if (orElse != null) {
    result = orElse();
  }

  return result;
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
      $bind2((T from, T to) => $effect($UpdateVar(from, to, cursor))),
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

bool $equals<T>(T value) {
  return value == $prev(value);
}

bool $identical<T>(T value) {
  return identical(value, $prev(value));
}

T $while<T>(bool condition(), T compute()) {
  compute = $bind0(compute);
  T result;
  for (; $unbind(() => condition());) {
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
  return $cache(compute, _iterableEquals(deps, $prev(deps)));
}

void $fork(Function() work()) {
  final cleanup = $cursor<Function()>(() => null);

  final maybeCleanup = () => $if(cleanup.value != null, cleanup.value);
  maybeCleanup();
  cleanup.value = work();
  $listen(($End _) => maybeCleanup());
}

void $listen<T>(void callback(T event)) {
  final cursor = $cursor(() => null);
  final listener = $bind(callback);
  $effect($AddListener(listener, cursor));
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
  final Function(T from, T to) onUpdate;

  _$VarImpl(T value, this.onUpdate) : _value = value;
}

class $UpdateVar<T> {
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

class $AddListener<T> {
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
