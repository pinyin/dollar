import 'package:dollar/dollar.dart';

/// combine handlers from right to left
/// every lefter handler is provided as the parent of the righter handler
$EffectHandlerCreator $combineHandlers(
    Iterable<$EffectHandlerCreator> createHandlers) {
  return createHandlers
      .reduce((l, r) => ($EffectHandler parent) => r(l(parent)));
}

$EffectHandlerCreator $listenAt($Listeners listeners) {
  return (parent) {
    return (effect) {
      if (effect is $AddListener) {
        listeners.add(effect.type, effect.callback, effect.at);
      } else {
        parent(effect);
      }
    };
  };
}

$EffectHandlerCreator $onUpdateVar(void onUpdate($UpdateVar effect)) {
  return (parent) {
    return (effect) {
      if (effect is $UpdateVar) {
        onUpdate(effect);
      } else {
        parent(effect);
      }
    };
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
    for (final cursor in (_cursors[event.runtimeType] ??= {})) {
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
