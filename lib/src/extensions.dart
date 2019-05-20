import 'package:dollar/dollar.dart';

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
      $bind((T from) =>
          $bind((T to) => $effect((cursor) => $UpdateVar(from, to, cursor)))),
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
    onUpdate(prevValue)(newValue);
  }

  T _value;
  final Function(T to) Function(T from) onUpdate;

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
