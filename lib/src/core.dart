import 'dart:collection';

dynamic $bind<T extends Function>(T func,
    [$EffectHandlerCreator createHandler]) {
  // TODO support function with arbitrary signature
  // TODO nullability of createHandler must be consistent across calls

  createHandler ??= _createDefaultHandler;
  final handler = createHandler(_handler ?? (effect) {});
  assert(handler != null);
  final context = _handler != null
      ? ($cursor(() => $Context()..context = _Context()).value)
      : ($Context()..context = _Context());

  return context
    ..handler = handler
    ..func = func;
}

final $EffectHandlerCreator _createDefaultHandler =
    (parent) => (effect) => {parent(effect)};

class $Context {
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

$Cursor<T> $cursor<T>(T init()) {
  final $Cursor<T> result =
      _context.cursor ??= _$CursorImpl<T>()..value = $isolate(init);
  _context.cursorNext();
  return result;
}

T $fork<T>(Object key, T logic()) {
  final contexts = $cursor(() => Map<Object, _Context>()).value;
  if (logic == null) return null;

  final prevContext = _context;
  _context = contexts[key] ??= _Context();
  _context.cursorReset();
  final result = logic();
  _context = prevContext;

  return result;
}

dynamic $raise(Object effect) {
  final prevContext = _context;
  _context = null;
  final result = _handler(effect);
  _context = prevContext;
  return result;
}

void $defer(void callback()) {
  _deferred ??= LinkedHashMap();
  _deferred[$cursor(() => null)] = callback;
}

typedef $EffectHandler = dynamic Function(Object effect);

typedef $EffectHandlerCreator = $EffectHandler Function($EffectHandler parent);

abstract class $Cursor<T> {
  T get value;
  set value(T newValue);

  T get() => value;
  T set(T newValue) => value = newValue;
}

class _$CursorImpl<T> extends $Cursor<T> {
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
  set cursor($Cursor status) => _cursor.cursor = status;

  $Cursor get cursor => _cursor.cursor;

  void cursorNext() {
    if (_cursor.next == null) _cursors.add(_$CursorInContext(null));
    _cursor = _cursor.next;
  }

  void cursorReset() => _cursor = _cursors.first;

  _$CursorInContext _cursor;
  final _cursors = LinkedList<_$CursorInContext>()
    ..addFirst(_$CursorInContext(null));

  _Context() {
    _cursor = _cursors.first;
    assert(_cursor != null);
  }
}

class _$CursorInContext extends LinkedListEntry<_$CursorInContext> {
  $Cursor cursor;

  _$CursorInContext(this.cursor);
}

_Context _context;

LinkedHashMap<$Cursor, Function()> _deferred;

$EffectHandler _handler;
