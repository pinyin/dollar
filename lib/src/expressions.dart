import 'package:collection/collection.dart';
import 'package:dollar/dollar.dart';

$Var<T> $var<T>(T init()) {
  final didInit = $cursor(() => false);
  final cursor = $cursor<$Var<T>>(() => null);
  final onUpdate = $handle((T to) {
    $effect((_) => $UpdateVar(to, cursor));
  });
  $if(!didInit.value, () {
    cursor.value = _$VarImpl(init(), onUpdate);
    didInit.value = true;
  });
  return cursor.value;
}

T $final<T>(T init()) {
  return $var(init).value;
}

T $previous<T>(T value) {
  final cursor = $cursor<T>(() => null);
  final prev = cursor.value;
  cursor.value = value;
  return prev;
}

bool $identical(Object value) {
  return identical(value, $previous(value));
}

bool $equals(Object value) {
  return value == $previous(value);
}

bool $shallowEquals(Iterable values) {
  return shallowEquals(values, $previous(values));
}

T $fork<T>(void Function() work($Var<T> result)) {
  final result = $var<T>(() => null);
  final cleanup = $cursor<void Function()>(() => null);

  $if(cleanup.value != null, cleanup.value);
  cleanup.value = work(result);

  return result.value;
}

R $listen<T, R>(R callback(T value)) {
  final latestCallback = $cursor<R Function(T)>(() => callback);
  latestCallback.value = callback;
  final result = $cursor<R>(() => null);
  final listener =
      $handle((T event) => result.value = latestCallback.value(event));
  $effect((cursor) => $AddListener(listener, cursor));
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
    _value = newValue;
    _onUpdate(newValue);
  }

  T _value;
  void Function(T to) _onUpdate;

  _$VarImpl(T value, void onUpdate(T to))
      : _value = value,
        _onUpdate = onUpdate;
}

final shallowEquals = const IterableEquality().equals;
