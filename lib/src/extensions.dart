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
        init(), $bind((T to) => $effect((_) => $UpdateVar(to, cursor))));
    didInit.value = true;
  });
  return cursor.value;
}

T $final<T>(T init(), [bool keep(T prev)]) {
  final didInit = $cursor(() => false);
  final cursor = $cursor<T>(() => null);
  final shouldRecompute = keep != null && !keep(cursor.value);
  $if(!didInit.value || shouldRecompute, () {
    cursor.value = init();
    didInit.value = true;
  });
  return cursor.value;
}

T $previous<T>(T value) {
  final curr = $cursor<T>(() => null);
  final prev = curr.value;
  curr.value = value;
  return prev;
}

R $diff<T, R>(T value, R diff(T prev, T curr)) {
  return diff($previous(value), value);
}

T $fork<T>($Effects<$Cursor<T>, Function()> work) {
  final result = $cursor<T>(() => null);
  final cleanup = $ref($previous(work(result)));

  final maybeCleanup = () => $if(cleanup.value != null, cleanup.value);

  maybeCleanup();
  $listen(($End _) => maybeCleanup());

  return result.value;
}

R $listen<T, R>($Effects<T, R> callback) {
  final latestCallback = $ref(callback);
  final result = $cursor<R>(() => null);
  final listener =
      $bind((T event) => result.value = latestCallback.value(event));
  $effect((cursor) => $AddListener(listener, cursor));
  return result.value;
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
