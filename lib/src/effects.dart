import 'package:collection/collection.dart';
import 'package:dollar/dollar.dart';

$Var<T> $var<T>(T init()) {
  final didInit = $ref(() => false);
  final ref = $ref<$Var<T>>(() => null);
  $if(!didInit.value, () {
    ref.value = _$VarImpl(ref, init(), $effect);
    didInit.value = true;
  });
  return ref.value;
}

T $final<T>(T init()) {
  return $var(init).value;
}

T $scan<T>(T work(T prev), [Iterable keys]) {
  final prevKeys = $ref<Iterable>(() => null);
  final status = $ref<T>(() => null);

  return $if(keys == null || !shallowEquals(prevKeys.value, keys), () {
    status.value = work(status.value);
    prevKeys.value = keys;
    return status.value;
  }, orElse: () => status.value);
}

R $listen<T, R>(R callback(T value)) {
  final listener = $ref<R Function(T)>(() => callback);
  listener.value = callback;
  final result = $ref<R>(() => null);

  $final(() {
    $effect($AddListener(
        $handle<T, R>((T event) => result.value = listener.value(event))));
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

  $Ref _ref;
  T _value;
  $EffectHandler _$effect;

  _$VarImpl($Ref ref, T value, $EffectHandler $effect)
      : _ref = ref,
        _value = value,
        _$effect = $effect;
}

class $UpdateVar<T> extends $Effect {
  final T from;
  final T to;
  final $Ref at;

  @override
  bool operator ==(other) {
    return other is $UpdateVar<T> &&
        other.runtimeType == runtimeType &&
        other.from == from &&
        other.to == to &&
        other.at == at;
  }

  @override
  int get hashCode => from.hashCode ^ to.hashCode;

  $UpdateVar(this.from, this.to, this.at);
}

class $AddListener<T> implements $Effect {
  final Function(T) callback;

  @override
  bool operator ==(other) {
    return other is $AddListener<T> &&
        other.runtimeType == runtimeType &&
        other.callback == callback;
  }

  @override
  int get hashCode => runtimeType.hashCode ^ callback.hashCode;

  $AddListener(this.callback);
}

class $RemoveListener<T> implements $Effect {
  final Function(T) callback;

  @override
  bool operator ==(other) {
    return other is $RemoveListener<T> &&
        other.runtimeType == runtimeType &&
        other.callback == callback;
  }

  @override
  int get hashCode => runtimeType.hashCode ^ callback.hashCode;

  $RemoveListener(this.callback);
}

final shallowEquals = const IterableEquality().equals;
