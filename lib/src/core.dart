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

enum _HooksZoneValue { handler, context }

class $BoundFunction {
  Function func;
  _Context context;
  $EffectHandler handler;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    context.cursorReset();

    return runZoned<dynamic>(
      () => Function.apply(
          func, invocation.positionalArguments, invocation.namedArguments),
      zoneValues: <_HooksZoneValue, dynamic>{
        _HooksZoneValue.handler: handler,
        _HooksZoneValue.context: context,
      },
    );
  }
}

T $isolate<T>(T func()) {
  return runZoned<T>(
    func,
    zoneValues: <_HooksZoneValue, dynamic>{
      _HooksZoneValue.handler: null,
      _HooksZoneValue.context: null,
    },
  );
}

$Property<T> $property<T>([T init()]) {
  final $Property<T> result = (_context.cursor ??= _$PropertyImpl<T>()
    ..value = init?.call()) as $Property<T>;
  _context.cursorNext();
  return result;
}

T $switch<T>(Object key, T logic()) {
  final contexts = $property(() => Map<Object, _Context>()).value;
  if (logic == null) return null;
  return runZoned(
    () {
      _context.cursorReset();
      return logic();
    },
    zoneValues: <_HooksZoneValue, dynamic>{
      _HooksZoneValue.handler: _handler,
      _HooksZoneValue.context: contexts[key] ??= _Context(),
    },
  );
  // TODO allow cleanup
}

dynamic $raise(Object effect) {
  return runZoned<dynamic>(
    () => _handler(effect),
    zoneValues: <_HooksZoneValue, dynamic>{
      _HooksZoneValue.handler: _handler,
      _HooksZoneValue.context: null,
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

class _$PropertyImpl<T> extends $Property<T> {
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
  set cursor($Property status) => _property.value = status;

  $Property get cursor => _property.value;

  void cursorNext() {
    if (_property.next == null) _properties.add(_$PropertyInContext(null));
    _property = _property.next;
  }

  void cursorReset() => _property = _properties.first;

  _$PropertyInContext _property;
  final _properties = LinkedList<_$PropertyInContext>()
    ..addFirst(_$PropertyInContext(null));

  _Context() {
    _property = _properties.first;
    assert(_property != null);
  }
}

class _$PropertyInContext extends LinkedListEntry<_$PropertyInContext> {
  $Property value;

  _$PropertyInContext(this.value);
}

_Context get _context => Zone.current[_HooksZoneValue.context] as _Context;

$EffectHandler get _handler =>
    Zone.current[_HooksZoneValue.handler] as $EffectHandler;

class $Exception {
  final Object error;
  final StackTrace stack;

  $Exception(this.error, this.stack);
}
