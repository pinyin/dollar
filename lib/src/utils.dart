import 'package:dollar/dollar.dart';

$EffectHandler $combineHandlers(Iterable<$EffectHandler> handlers) {
  return ($Effect effect) {
    handlers.forEach((handler) => handler(effect));
  };
}

$EffectHandler $listenAt($Listeners listeners) {
  return (effect) {
    if (effect is $AddListener) {
      listeners.add(effect.type, effect.callback);
    }
  };
}

class $Listeners {
  add(Type eventType, Function callback) {
    (_map[eventType] ??= {}).add(callback);
  }

  trigger<T>(T event) {
    _map[event.runtimeType].forEach((callback) => callback(event));
  }

  final _map = Map<Type, Set<Function>>();
}
