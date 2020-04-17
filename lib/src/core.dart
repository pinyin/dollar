import 'dart:async';
import 'dart:collection';

dynamic $bind<T extends Function>(T func,
    [$EffectHandlerCreator createHandler]) {
  createHandler ??= _createDefaultHandler;
  final handler = createHandler(_handler ?? (effect) {});
  assert(handler != null);
  final isInAnotherBindFunction = _handler != null;
  final boundFunction = isInAnotherBindFunction
      ? ($property(() => $BoundFunction()..context = _Context()).value)
      : ($BoundFunction()..context = _Context());

  return boundFunction
    ..handler = handler
    ..func = func;
}

final _bind = $bind;

extension $Bind on Function {
  dynamic $bind([$EffectHandlerCreator createHandler]) =>
      _bind(this, createHandler);
}

final $EffectHandlerCreator _createDefaultHandler =
    (context) => (effect) => context(effect);

enum _HooksZoneValue { handler, cursor }

class $BoundFunction {
  Function func;
  _Context context;
  $EffectHandler handler;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return runZoned<dynamic>(
      () => Function.apply(
          func, invocation.positionalArguments, invocation.namedArguments),
      zoneValues: <_HooksZoneValue, dynamic>{
        _HooksZoneValue.handler: handler,
        _HooksZoneValue.cursor: context.cursor,
      },
    );
  }
}

T $isolate<T>(T func()) {
  return runZoned<T>(
    func,
    zoneValues: <_HooksZoneValue, dynamic>{
      _HooksZoneValue.handler: null,
      _HooksZoneValue.cursor: null,
    },
  );
}

$Property<T> $property<T>([T init()]) {
  return _cursor.next<T>()..value ??= init?.call();
}

T $switch<T>(Object key, T logic()) {
  final contexts = $property(() => Map<Object, _Context>()).value;
  if (logic == null) return null;
  return runZoned(
    () => logic(),
    zoneValues: <_HooksZoneValue, dynamic>{
      _HooksZoneValue.handler: _handler,
      _HooksZoneValue.cursor: (contexts[key] ??= _Context()).cursor,
    },
  );
  // TODO allow cleanup
}

dynamic $raise(Object effect) {
  return runZoned<dynamic>(
    () => _handler(effect),
    zoneValues: <_HooksZoneValue, dynamic>{
      _HooksZoneValue.handler: _handler,
      _HooksZoneValue.cursor: null,
    },
  );
}

typedef $EffectHandler = dynamic Function(Object effect);

typedef $EffectHandlerCreator = $EffectHandler Function($EffectHandler context);

abstract class $Property<T> {
  T get value;

  set value(T newValue);

  T get() => value;

  T set(T newValue) => value = newValue;
}

class _PropertyImpl<T> extends $Property<T> {
  @override
  T get value => _value;

  @override
  set value(T newValue) => _value = newValue;

  @override
  T get() => value;

  @override
  T set(T newValue) => value = newValue;

  T _value;
}

class _Context {
  _Cursor get cursor => _Cursor(_properties.first);

  final _properties = LinkedList<_PropertyInContext>()
    ..addFirst(_PropertyInContext(null));
}

class _Cursor {
  $Property<T> next<T>() {
    if (_entry.next == null)
      _entry.list.add(_PropertyInContext(_PropertyImpl<T>()));
    _entry = _entry.next;
    return _entry.value as $Property<T>;
  }

  _PropertyInContext _entry;

  _Cursor(this._entry);
}

class _PropertyInContext extends LinkedListEntry<_PropertyInContext> {
  $Property value;

  _PropertyInContext(this.value);
}

_Cursor get _cursor => Zone.current[_HooksZoneValue.cursor] as _Cursor;

$EffectHandler get _handler =>
    Zone.current[_HooksZoneValue.handler] as $EffectHandler;

class $Exception {
  final Object error;
  final StackTrace stack;

  $Exception(this.error, this.stack);
}
