import 'package:collection/collection.dart';
import 'package:dollar/dollar.dart';

$Var<T> $var<T>(T init()) {
  final didInit = $cursor(() => false);
  final cursor = $cursor<$Var<T>>(() => null);
  $if(!didInit.value, () {
    cursor.value = _$VarImpl(
        init(), $handle((T to) => $effect((_) => $UpdateVar(to, cursor))));
    didInit.value = true;
  });
  return cursor.value;
}

T $final<T>(T init()) {
  return $var(init).value;
}

T $previous<T>(T value) {
  final curr = $cursor<T>(() => null);
  curr.value = value;
  final prev = $cursor<T>(() => null);
  $listen(($Pass _) => prev.value = curr.value);
  return prev.value;
}

bool $identical(Object value) {
  return identical(value, $previous(value));
}

bool $equals(Object value) {
  return value == $previous(value);
}

bool $shallowEquals(Iterable values) {
  return _shallowEquals(values, $previous(values));
}

T $fork<T>($Effects<$Var<T>, Function()> work) {
  final result = $var<T>(() => null);
  final cleanup = $cursor<Function()>(() => null);
  final maybeCleanup = () => $if(cleanup.value != null, cleanup.value);

  maybeCleanup();
  cleanup.value = work(result);

  $listen(($End _) => maybeCleanup());

  return result.value;
}

R $listen<T, R>($Effects<T, R> callback) {
  final latestCallback = $cursor(() => callback);
  latestCallback.value = callback;
  final result = $cursor<R>(() => null);
  final listener =
      $handle((T event) => result.value = latestCallback.value(event));
  $final(() => $effect((cursor) => $AddListener(listener, cursor)));
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
  $Effects<T, void> _onUpdate;

  _$VarImpl(T value, $Effects<T, void> onUpdate)
      : _value = value,
        _onUpdate = onUpdate;
}

class $UpdateVar<T> extends $Effect {
  final T to;
  final $Cursor at;

  @override
  bool operator ==(other) {
    return other is $UpdateVar<T> &&
        other.runtimeType == runtimeType &&
        other.to == to &&
        other.at == at;
  }

  @override
  int get hashCode => to.hashCode;

  $UpdateVar(this.to, this.at);
}

class $AddListener<T> implements $Effect {
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

class $Pass {}

class $End {}

final _shallowEquals = const IterableEquality().equals;