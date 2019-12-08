import 'dart:collection';

dynamic $bind<T extends Function>(T func,
    [$EffectHandlerCreator createHandler]) {
  // TODO support function with arbitrary signature
  // TODO nullability of createHandler must be consistent across calls

  createHandler ??= _createDefaultHandler;
  final handler = createHandler(_handler ?? (effect) {});
  assert(handler != null);
  final boundFunction = _handler != null
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

class $BoundFunction {
  Function func;
  _Context context;
  $EffectHandler handler;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    context.cursorReset();

    final prevHandler = _handler;
    final prevContext = _context;
    final prevDeferred = _deferred;
    dynamic result;

    try {
      _handler = handler;
      _context = context;
      _deferred = null;

      result = Function.apply(
          func, invocation.positionalArguments, invocation.namedArguments);
      // TODO support generator
      // we may never be able to support async functions though.

      assert(identical(_context, context));
      assert(identical(_handler, handler));
    } finally {
      if (_deferred != null) {
        for (final cleanup in _deferred.values) {
          cleanup();
        }
      }
      _deferred = prevDeferred;
      _context = prevContext;
      _handler = prevHandler;
    }

    return result;
  }
}

T $isolate<T>(T func()) {
  final prevHandler = _handler;
  final prevContext = _context;
  final prevDeferred = _deferred;

  _handler = null;
  _context = null;
  _deferred = null;

  final result = func();

  assert(identical(_context, null));
  assert(identical(_handler, null));

  _deferred = prevDeferred;
  _context = prevContext;
  _handler = prevHandler;
  return result;
}

$Property<T> $property<T>(T init()) {
  final $Property<T> result =
      (_context.cursor ??= _$PropertyImpl<T>()..value = init()) as $Property<T>;
  _context.cursorNext();
  return result;
}

T $switch<T>(Object key, T logic()) {
  final contexts = $property(() => Map<Object, _Context>()).value;
  if (logic == null) return null;

  final prevContext = _context;
  _context = contexts[key] ??= _Context();
  _context.cursorReset();
  final result = logic();
  _context = prevContext;
  // TODO allow cleanup

  return result;
}

dynamic $raise(Object effect) {
  final prevContext = _context;
  _context = null;
  final dynamic result = _handler(effect);
  _context = prevContext;
  return result;
}

void $defer(void callback()) {
  _deferred ??= LinkedHashMap();
  _deferred[$property<dynamic>(() => null)] = callback;
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

_Context _context;

LinkedHashMap<$Property, Function()> _deferred;

$EffectHandler _handler;
