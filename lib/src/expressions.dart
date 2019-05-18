import 'package:collection/collection.dart';
import 'package:dollar/dollar.dart';

$Var<T> $var<T>(T init()) {
  final didInit = $cursor(() => false);
  final ref = $cursor<$Var<T>>(() => null);
  $if(!didInit.value, () {
    ref.value = _$VarImpl(ref, init(), $effect);
    didInit.value = true;
  });
  return ref.value;
}

T $final<T>(T init()) {
  return $var(init).value;
}

T $previous<T>(T value) {
  final ref = $cursor<T>(() => null);
  final prev = ref.value;
  ref.value = value;
  return prev;
}

bool $identical(Object value) {
  return identical(value, $previous(value));
}

bool $shallowEquals(Iterable values) {
  return shallowEquals(values, $previous(values));
}

R $listen<T, R>(R callback(T value)) {
  final listener = $cursor<R Function(T)>(() => callback);
  listener.value = callback;
  final result = $cursor<R>(() => null);

  $final(() {
    $effect($AddListener(
        $handle((T event) => result.value = listener.value(event)), result));
  });

  return result.value;
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
    final effect = $UpdateVar(_value, newValue, _ref);
    _value = newValue;
    _$effect(effect);
  }

  $Cursor _ref;
  T _value;
  $EffectHandler _$effect;

  _$VarImpl($Cursor ref, T value, $EffectHandler $effect)
      : _ref = ref,
        _value = value,
        _$effect = $effect;
}

final shallowEquals = const IterableEquality().equals;
