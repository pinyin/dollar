import 'package:collection/collection.dart';
import 'package:dollar/dollar.dart';

$Var<T> $var<T>(T init()) {
  final ref = $ref<$Var<T>>(() => null);
  $if(ref.value == null, () {
    ref.value = _$VarImpl(ref, init(), $effect);
  });
  return ref.value;
}

R $scan<R>(R work(R prev, Iterable prevKeys), Iterable keys) {
  final prevKeys = $ref(() => keys);
  final status = $ref<R>(() => null);

  return $if(status.value == null || !shallowEquals(prevKeys.value, keys), () {
    status.value = work(status.value, prevKeys.value);
    prevKeys.value = keys;
    return status.value;
  }, orElse: () => status.value);
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
    final effect = $VarUpdateEffect(_value, newValue, _ref);
    _value = newValue;
    _$effect(effect);
  }

  $Ref _ref;
  T _value;
  $EffectHandler _$effect;

  _$VarImpl($Ref ref, T value, $EffectHandler $effect)
      : _ref = ref,
        _value = value,
        _$effect = $effect;
}

class $VarUpdateEffect<T> extends $Effect {
  final T from;
  final T to;
  final $Ref at;

  @override
  bool operator ==(other) {
    return other is $VarUpdateEffect && other.from == from && other.to == to;
  }

  @override
  int get hashCode => from.hashCode ^ to.hashCode;

  $VarUpdateEffect(this.from, this.to, this.at);
}

final shallowEquals = const IterableEquality().equals;
