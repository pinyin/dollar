import 'package:collection/collection.dart';
import 'package:dollar/dollar.dart';

$Var<T> $var<T>(T init()) {
  return $ref(() => _$VarImpl(init(), $effect)).value;
}

abstract class $Var<T> extends $Ref<T> {}

class _$VarImpl<T> extends $Var<T> {
  @override
  T get value => _value;

  @override
  set value(T newValue) {
    final effect = $VarUpdateEffect(_value, newValue);
    _value = newValue;
    _$effect(effect);
  }

  T _value;
  $EffectHandler _$effect;

  _$VarImpl(T value, $EffectHandler $effect)
      : _value = value,
        _$effect = $effect;
}

class $VarUpdateEffect<T> {
  final T from;
  final T to;

  @override
  bool operator ==(other) {
    return other is $VarUpdateEffect && other.from == from && other.to == to;
  }

  @override
  int get hashCode => from.hashCode ^ to.hashCode;

  $VarUpdateEffect(this.from, this.to);
}

void $scan<R extends Function()>(
    R work(R prev, Iterable prevKeys), Iterable keys) {
  final prevKeys = $ref(() => keys);
  final status = $ref<R>(() => null);

  $if(status.value == null || !shallowEquals(prevKeys.value, keys), () {
    $if(status.value != null, () {
      print(status.value);
      (status.value as dynamic)();
      $effect($CleanedUpEffect(status.value));
    });
    status.value = work(status.value, prevKeys.value);
    $effect($NeedCleanUpEffect(status.value));
    prevKeys.value = keys;
  });
}

class $NeedCleanUpEffect {
  final Function() status;

  $NeedCleanUpEffect(this.status);
}

class $CleanedUpEffect {
  final Function() status;

  $CleanedUpEffect(this.status);
}

final shallowEquals = const IterableEquality().equals;
