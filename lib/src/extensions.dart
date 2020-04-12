import 'package:dollar/dollar.dart';

R Function(A, B, C, D) $bind4<R, A, B, C, D>(R func(A a, B b, C c, D d),
    [$EffectHandlerCreator createHandler]) {
  final dynamic inner = $bind(
      (A a, B b, C c, D d, void e, void f, void g) => func(a, b, c, d),
      createHandler);
  return (a, b, c, d) => inner(a, b, c, d, null, null, null) as R;
}

extension $Bind4<R, A, B, C, D> on R Function(A, B, C, D) {
  R Function(A, B, C, D) $bind([$EffectHandlerCreator createHandler]) =>
      $bind4(this, createHandler);
}

R Function(A, B, C) $bind3<R, A, B, C>(R func(A a, B b, C c),
    [$EffectHandlerCreator createHandler]) {
  final dynamic inner = $bind(
      (A a, B b, C c, void d, void e, void f, void g) => func(a, b, c),
      createHandler);
  return (a, b, c) => inner(a, b, c, null, null, null, null) as R;
}

extension $Bind3<R, A, B, C> on R Function(A, B, C) {
  R Function(A, B, C) $bind([$EffectHandlerCreator createHandler]) =>
      $bind3(this, createHandler);
}

R Function(A, B) $bind2<R, A, B>(R func(A a, B b),
    [$EffectHandlerCreator createHandler]) {
  final dynamic inner = $bind(
      (A a, B b, void c, void d, void e, void f, void g) => func(a, b),
      createHandler);
  return (a, b) => inner(a, b, null, null, null, null, null) as R;
}

extension $Bind2<R, A, B> on R Function(A, B) {
  R Function(A, B) $bind([$EffectHandlerCreator createHandler]) =>
      $bind2(this, createHandler);
}

R Function(A) $bind1<R, A>(R func(A a), [$EffectHandlerCreator createHandler]) {
  final dynamic inner = $bind(
      (A a, void b, void c, void d, void e, void f, void g) => func(a),
      createHandler);
  return (a) => inner(a, null, null, null, null, null, null) as R;
}

extension $Bind1<R, A> on R Function(A) {
  R Function(A) $bind([$EffectHandlerCreator createHandler]) =>
      $bind1(this, createHandler);
}

R Function() $bind0<R>(R func(), [$EffectHandlerCreator createHandler]) {
  final dynamic inner = $bind(
      (void a, void b, void c, void d, void e, void f, void g) => func(),
      createHandler);
  return () => inner(null, null, null, null, null, null, null) as R;
}

extension $Bind0<R> on R Function() {
  R Function() $bind([$EffectHandlerCreator createHandler]) =>
      $bind0(this, createHandler);
}

mixin $Method {
  T $method<T>(Function method, T Function() logic) {
    _bind ??= $isolate(() {
      return $Bind2((Function method, dynamic Function() callback) {
        return $switch<dynamic>(method, callback);
      }).$bind($handle);
    });
    return _bind(method, logic) as T;
  }

  $EffectHandlerCreator get $handle => (_) => (_) {};

  void $reset() {
    _bind = null;
  }

  dynamic Function(Function method, dynamic Function()) _bind;
}

T $if<T>(bool condition, T then(), {T orElse()}) {
  return $switch(condition, () {
    return condition ? then?.call() : orElse?.call();
  });
}

T $unless<T>(bool condition, T run()) {
  return $if(!condition, run);
}

$Ref<T> $ref<T>(T value) {
  final property = $property<_$RefImpl<T>>(() => _$RefImpl(value));
  property.value.value = value;
  return property.value;
}

final _ref = $ref;

extension $RefExtension<T> on T {
  $Ref<T> get $ref => _ref<T>(this);
}

$Var<T> $var<T>(T init()) {
  final didInit = $property(() => false);
  final value = $property<$Var<T>>(() => null);
  $if(!didInit.value, () {
    value.value = _$VarImpl<T>(
      init(),
      $bind2<void, T, T>(
          (T from, T to) => $raise($VarUpdated(from, to, value))),
    );
    didInit.value = true;
  });
  return value.value;
}

T $cache<T>(T compute(), bool reusable) {
  final didInit = $property(() => false);
  final cached = $property<T>(() => null);
  $if(!didInit.value || !reusable, () {
    cached.value = $bind0(compute, (handle) {
      return (effect) {
        if (effect is $VarUpdated) didInit.value = false;
        handle(effect);
      };
    })();
    didInit.value = true;
  });
  return cached.value;
}

T $final<T>(T init()) {
  return $cache<T>(() => init(), true);
}

T $prev<T>(T value) {
  final curr = $property<T>(() => null);
  final prev = curr.value;
  curr.value = value;
  return prev;
}

final _prev = $prev;

extension $Prev<T> on T {
  T get $prev => _prev<T>(this);
}

T $distinct<T>(T value, [bool equals(T a, T b)]) {
  final curr = $property<T>(() => null);
  final shouldUpdate = curr.value == null ||
      !(equals?.call(curr.value, value) ?? curr.value == value);
  if (shouldUpdate) curr.value = value;
  return curr.value;
}

T $while<T>(bool condition(), T compute()) {
  compute = $bind0(compute);
  T result;
  for (; $isolate(() => condition());) {
    result = compute();
  }
  return result;
}

void $forEach<E>(Iterable<E> iterable, void f(E element)) {
  f = $bind1(f);
  var i = 0;
  for (E element in iterable) {
    f(element);
    i++;
  }
}

const _forEach = $forEach;

extension $ForEach<T> on Iterable<T> {
  void $forEach(void f(T element)) => _forEach<T>(this, f);
}

R $interpolate<T, R>(T value, R diff(T prev, T curr)) {
  return diff($prev(value), value);
}

R $aggregate<T, R>(T value, R aggregator(R aggregate, T value)) {
  final aggregated = $property<R>(() => null);
  aggregated.value = aggregator(aggregated.value, value);
  return aggregated.value;
}

T $generate<T>(T compute(T prev)) {
  final generated = $property<T>(() => null);
  generated.value = compute(generated.value);
  return generated.value;
}

T $memo<T>(T compute(), Iterable<dynamic> deps) {
  return $cache(compute, deps.shallowEqualsTo($prev(deps)));
}

void $async(Function() work()) {
  final cleanup = $property<Function()>(() => null);

  final maybeCleanup = () => $if<void>(cleanup.value != null, cleanup.value);
  maybeCleanup();
  cleanup.value = work();
  $listen(($ContextTerminated _) => maybeCleanup());
}

void $effect(Function() effect(), Iterable<dynamic> deps) {
  $memo(() => $async(effect), deps);
}

void $listen<T>(void callback(T event)) {
  final at = $property(() => null);
  final listener = $bind1(callback);
  $raise($Listened(listener, at));
}

abstract class $Ref<T> {
  T get value;
  T get() => value;
}

class _$RefImpl<T> extends $Ref<T> {
  @override
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
  final $Property at;
  final T from;
  final T to;

  @override
  bool operator ==(dynamic other) {
    return other is $VarUpdated<T> &&
        other.runtimeType == runtimeType &&
        other.at == at;
  }

  @override
  int get hashCode => at.hashCode;

  $VarUpdated(this.from, this.to, this.at);
}

class $Listened<T> {
  final $Property at;
  final Function callback;
  final Type type;

  @override
  bool operator ==(dynamic other) {
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

class $ContextTerminated {
  const $ContextTerminated();
}

$EffectHandlerCreator $onListened($Listeners listeners) {
  return (handle) {
    return (effect) {
      if (effect is $Listened) {
        listeners.add(effect.type, effect.callback, effect.at);
      } else {
        return handle(effect);
      }
    };
  };
}

$EffectHandlerCreator $onVarUpdated(dynamic onUpdate($VarUpdated effect)) {
  return (handle) {
    return (effect) {
      if (effect is $VarUpdated) {
        return onUpdate(effect);
      } else {
        return handle(effect);
      }
    };
  };
}

class $Listeners {
  void add(Type eventType, Function callback, $Property at) {
    assert(_types[at] == null || _types[at] == eventType);
    _types[at] = eventType;
    (_properties[eventType] ??= {}).add(at);
    _callbacks[at] = callback;
  }

  void trigger<T>(T event) {
    for (final property in (_properties[event.runtimeType] ??= {})) {
      final callback = _callbacks[property];
      if (callback is Function) {
        callback(event);
      }
    }
  }

  final _properties = Map<Type, Set<$Property>>();
  final _callbacks = Map<$Property, Function>();
  final _types = Map<$Property, Type>();
}
