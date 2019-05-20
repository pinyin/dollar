import 'package:dollar/dollar.dart';

$EffectHandler $combineHandlers(Iterable<$EffectHandler> handlers) {
  return ($Effect effect) {
    for (final handler in handlers) {
      if (handler is $EffectHandler) handler(effect);
    }
  };
}

$EffectHandler $listenAt($Listeners listeners) {
  return (effect) {
    if (effect is $AddListener) {
      listeners.add(effect.type, effect.callback, effect.at);
    }
  };
}

R Function(T) $convergeVars<T, R>(R func(T params), [$EffectHandler handler]) {
  var isInconsistent = false;
  final bindFunc = $bind(
      func,
      $combineHandlers([
        (effect) => isInconsistent = isInconsistent || effect is $UpdateVar,
        handler
      ]));

  return (T params) {
    R result;
    do {
      isInconsistent = false;
      result = bindFunc(params);
    } while (isInconsistent);
    return result;
  };
}

class $Listeners {
  add(Type eventType, Function callback, $Cursor at) {
    assert(_types[at] == null || _types[at] == eventType);
    _types[at] = eventType;
    (_cursors[eventType] ??= {}).add(at);
    _callbacks[at] = callback;
  }

  trigger<T>(T event) {
    for (final cursor in _cursors[event.runtimeType]) {
      final callback = _callbacks[cursor];
      if (callback is Function) {
        callback(event);
      }
    }
  }

  final _cursors = Map<Type, Set<$Cursor>>();
  final _callbacks = Map<$Cursor, Function>();
  final _types = Map<$Cursor, Type>();
}
