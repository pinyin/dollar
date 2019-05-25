import 'dart:async';

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

$EffectHandler $onUpdateVar(void onUpdate($UpdateVar effect)) {
  return (effect) {
    if (effect is $UpdateVar) onUpdate(effect);
  };
}

Stream<R> Function(T) $convergeVars<T, R>(R func(T params),
    [$EffectHandler handler]) {
  final latestInput = _Ref<T>(null);
  var isInconsistent = false;
  var didScheduleTask = false;

  final outputController = StreamController<R>();
  final output = outputController.stream.asBroadcastStream();

  final handleUpdateVar = ($Effect effect) {
    isInconsistent = isInconsistent || effect is $UpdateVar;

    if (isInconsistent && !didScheduleTask) {
      didScheduleTask = true;
      scheduleMicrotask(() {
        if (!isInconsistent) return;
        isInconsistent = false;
        didScheduleTask = false;
        outputController.add(func(latestInput.value));
      });
    }
  };

  func = $bind(func, $combineHandlers([handleUpdateVar, handler]));

  return (T params) {
    latestInput.value = params;
    final result = func(params);
    if (!isInconsistent) outputController.add(result);
    return output;
  };
}

class _Ref<T> {
  T value;
  _Ref(this.value);
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
