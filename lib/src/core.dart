import 'dart:collection';

R Function(A, B, C, D, E, F, G) $bind7<R, A, B, C, D, E, F, G>(
    R func(A a, B b, C c, D d, E e, F f, G g),
    [$EffectHandler handler]) {
  // TODO support function with arbitrary signature

  final context =
      handler != null ? _Context() : $cursor(() => _Context()).value;
  handler ??= _handler;

  return (A a, B b, C c, D d, E e, F f, G g) {
    context.cursorReset();

    //region Wrap func in bind context
    final prevHandler = _handler;
    final prevContext = _context;

    _handler = handler;
    _context = context;

    final result = func(a, b, c, d, e, f, g);

    assert(identical(_context, context));
    assert(identical(_handler, handler));

    _context = prevContext;
    _handler = prevHandler;
    //endregion

    return result;
  };
}

$Cursor<T> $cursor<T>(T init()) {
  final $Cursor<T> result = _context.cursor ??= () {
    //region Init cursor
    final prevContext = _context;
    _context = null;
    final cursor = _$CursorImpl<T>();
    cursor.value = init();
    assert(_context == null);
    _context = prevContext;
    return cursor;
    //endregion
  }();
  _context.cursorNext();
  return result;
}

T $if<T>(bool condition, T then(), {T orElse()}) {
  final thenCursors = $cursor(() => _Context());
  final orElseCursors = $cursor(() => _Context());

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

T $effect<T>($Effect createEffect($Cursor cursor)) {
  final cursor = $cursor<T>(() => null);
  final prevContext = _context;
  _context = null;
  if (_handler != null) _handler(createEffect(cursor));
  _context = prevContext;
  return cursor.value;
}

abstract class $Effect {
  $Cursor get at;
}

typedef $EffectHandler = void Function($Effect effect);

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

$EffectHandler _handler;
