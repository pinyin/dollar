import 'package:dollar/dollar.dart';

$EffectHandler $combineHandlers(Iterable<$EffectHandler> handlers) {
  return ($Effect effect) {
    handlers.forEach((handler) => handler(effect));
  };
}

$EffectHandler $listenAt($Listeners listeners) {
  return (effect) {
    if (effect is $AddListener) {
      listeners.add(effect.type, effect.callback, effect.at);
    }
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
