import 'package:dollar/dollar.dart';

R Function(A, B, C, D) $context4<R, A, B, C, D>(R func(A a, B b, C c, D d),
    {$EffectHandlerCreator? onEffect}) {
  final dynamic inner =
      $context((A a, B b, C c, D d) => func(a, b, c, d), onEffect: onEffect);
  return (a, b, c, d) => inner(a, b, c, d) as R;
}

R Function(A, B, C) $context3<R, A, B, C>(R func(A a, B b, C c),
    {$EffectHandlerCreator? onEffect}) {
  final dynamic inner =
      $context((A a, B b, C c) => func(a, b, c), onEffect: onEffect);
  return (a, b, c) => inner(a, b, c) as R;
}

R Function(A, B) $context2<R, A, B>(R func(A a, B b),
    {$EffectHandlerCreator? onEffect}) {
  final dynamic inner = $context((A a, B b) => func(a, b), onEffect: onEffect);
  return (a, b) => inner(a, b) as R;
}

R Function(A) $context1<R, A>(R func(A a), {$EffectHandlerCreator? onEffect}) {
  final dynamic inner = $context((A a) => func(a), onEffect: onEffect);
  return (a) => inner(a) as R;
}

R Function() $context0<R>(R func(), {$EffectHandlerCreator? onEffect}) {
  final dynamic inner = $context(() => func(), onEffect: onEffect);
  return () => inner() as R;
}

mixin $Method {
  T $method<T>(Function method, T Function() logic) {
    _bind ??= $context2<dynamic, Function, dynamic Function()>(
        (Function method, dynamic Function() logic) {
      $fork(method);
      final dynamic result = logic();
      $merge();
      return result;
    }, onEffect: $handle);
    return _bind!(method, logic) as T;
  }

  $EffectHandlerCreator get $handle => (_) => (_) => null;

  void $reset() {
    _bind = null;
  }

  dynamic Function(Function method, dynamic Function())? _bind;
}

$Ref<T> $ref<T>(T value) {
  final property = $value<_$RefImpl<T>>(() => _$RefImpl(value));
  property.value.value = value;
  return property.value;
}

final _ref = $ref;

extension $RefExtension<T> on T {
  $Ref<T> get $ref => _ref<T>(this);
}

T $cache<T>(T compute(), bool reusable) {
  final cached = $value<T?>(() => null);
  final isFirstRun = $value(() => true);

  final needCompute = (!reusable && !isFirstRun.value) || isFirstRun.value;
  $fork(needCompute);
  if (needCompute) {
    cached.value = compute();
  }
  $merge();

  isFirstRun.value = false;
  return cached.value as T;
}

T $final<T>(T init()) {
  return $value(init).value;
}

$Var<T> $var<T>(T init()) {
  final updated = $final(() => $context0(() {
        $effect($VarUpdated());
      }, onEffect: (p) => (e) => p?.call(e)));
  return $final<$Var<T>>(() => _$VarImpl<T>(init(), updated));
}

T? $prev<T>(T value) {
  final curr = $value<T?>(() => null);
  final prev = curr.value;
  curr.value = value;
  return prev;
}

bool $isInit() {
  final curr = $prev(false);
  return curr ?? true;
}

final _prev = $prev;

extension $Prev<T> on T {
  T? get $prev => _prev<T>(this);
}

T? $distinct<T>(T value, [bool equals(T? a, T b)?]) {
  final curr = $value<T?>(() => null);
  final shouldUpdate = curr.value == null ||
      !(equals?.call(curr.value, value) ?? curr.value == value);
  if (shouldUpdate) curr.value = value;
  return curr.value;
}

R $interpolate<T, R>(T value, R diff(T? prev, T curr)) {
  return diff($prev(value), value);
}

R? $aggregate<T, R>(T value, R aggregator(R? aggregate, T value)) {
  final aggregated = $value<R?>(() => null);
  aggregated.value = aggregator(aggregated.value, value);
  return aggregated.value;
}

T? $generate<T>(T compute(T? prev)) {
  final generated = $value<T?>(() => null);
  generated.value = compute(generated.value);
  return generated.value;
}

T $memo<T>(T compute(), Iterable<dynamic> deps) {
  return $cache(compute, deps.shallowEqualsTo($prev(deps)));
}

abstract class $Ref<T> {
  T get value;

  T get() => value;

  set value(T to);

  void set(T to);
}

class _$RefImpl<T> extends $Ref<T> {
  @override
  T value;

  _$RefImpl(this.value);

  @override
  void set(T to) => value = to;
}

abstract class $Var<T> extends $Ref<T> {
  @override
  set value(T newValue);

  @override
  T set(T newValue) => value = newValue;
}

class _$VarImpl<T> extends $Var<T> {
  @override
  T get value => _value;

  @override
  set value(T newValue) {
    _value = newValue;
    onUpdate();
  }

  T _value;
  final Function() onUpdate;

  _$VarImpl(T value, this.onUpdate) : _value = value;
}

class $VarUpdated {}
