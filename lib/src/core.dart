import 'dart:collection';

R Function(T) $handle<T, R>(R func(T params), [$EffectHandler handler]) {
  assert(_handler == null || handler == null);
  assert(_handler != null || handler != null);

  final context = _context == null ? _Context() : $ref(() => _Context()).value;
  handler ??= _handler;

  return (T params) {
    context.cursorReset();

    final prevHandler = _handler;
    final prevContext = _context;

    _handler = handler;
    _context = context;

    final result = func(params);

    assert(identical(_context, context));
    assert(identical(_handler, handler));

    _context = prevContext;
    _handler = prevHandler;

    return result;
  };
}

T $cursor<T>(T effects()) {
  final context = $ref(() => _Context()).value;
  context.cursorReset();
  final lastEffects = $ref(() => effects);
  lastEffects.value = effects;
  final result = $ref<T>(() => null);

  // TODO automatically skip
  final prevContext = _context;
  _context = context;
  result.value = lastEffects.value();
  assert(identical(_context, context));
  _context = prevContext;

  return result.value;
}

$Ref<T> $ref<T>(T init()) {
  final $Ref<T> result = _context.cursor ??= _$RefImpl<T>()..value = init();
  _context.cursorNext();
  return result;
}

T $if<T>(bool condition, T then(), {T orElse()}) {
  final thenCursors = $ref(() => _Context());
  final orElseCursors = $ref(() => _Context());

  T result;

  final prevCursors = _context;
  if (condition) {
    _context = thenCursors.value;
    _context.cursorReset();
    result = then();
    assert(identical(_context, thenCursors.value));
  } else if (orElse != null) {
    _context = orElseCursors.value;
    _context.cursorReset();
    result = orElse();
    assert(identical(_context, orElseCursors.value));
  }
  _context = prevCursors;

  return result;
}

$EffectHandler get $effect => _handler;

abstract class $Effect {
  $Ref get at;
}

typedef $EffectHandler = void Function($Effect effect);

abstract class $Ref<T> {
  T get value;
  set value(T newValue);

  T get() => value;
  T set(T newValue) => value = newValue;
}

class _$RefImpl<T> extends $Ref<T> {
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
  set cursor($Ref status) => _cursor.ref = status;

  $Ref get cursor => _cursor.ref;

  void cursorNext() {
    if (_cursor.next == null) _cursors.add(_$RefInContext(null));
    _cursor = _cursor.next;
  }

  void cursorReset() => _cursor = _cursors.first;

  _$RefInContext _cursor;
  final _cursors = LinkedList<_$RefInContext>()..addFirst(_$RefInContext(null));

  _Context() {
    _cursor = _cursors.first;
    assert(_cursor != null);
  }
}

class _$RefInContext extends LinkedListEntry<_$RefInContext> {
  $Ref ref;

  _$RefInContext(this.ref);
}

_Context _context;

$EffectHandler _handler;

typedef $Effects<T, R> = R Function(T);
