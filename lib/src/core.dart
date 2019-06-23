import 'dart:collection';

R Function(A, B, C, D, E, F, G) $bind7<R, A, B, C, D, E, F, G>(
    R func(A a, B b, C c, D d, E e, F f, G g),
    [$EffectHandlerCreator createHandler]) {
  // TODO support function with arbitrary signature
  // TODO nullability of createHandler must be consistent across calls

  final handler =
      createHandler == null ? _handler : createHandler(_handler ?? (_) {});
  assert(handler != null);
  final context =
      _handler != null ? $cursor(() => _Context()).value : _Context();

  return (A a, B b, C c, D d, E e, F f, G g) {
    context.cursorReset();

    final prevHandler = _handler;
    final prevContext = _context;

    _handler = handler;
    _context = context;

    final result = func(a, b, c, d, e, f, g);

    assert(identical(_context, context));
    assert(identical(_handler, handler));

    _context = prevContext;
    _handler = prevHandler;

    return result;
  };
}

void $unbind(void func()) {
  final prevHandler = _handler;
  final prevContext = _context;

  _handler = null;
  _context = null;

  func();

  assert(identical(_context, null));
  assert(identical(_handler, null));

  _context = prevContext;
  _handler = prevHandler;
}

$EffectHandlerCreator $emptyHandler = (parent) => parent;

$Cursor<T> $cursor<T>(T init()) {
  final $Cursor<T> result = _context.cursor ??= () {
    final prevContext = _context;
    _context = null;
    final cursor = _$CursorImpl<T>();
    cursor.value = init();
    assert(_context == null);
    _context = prevContext;
    return cursor;
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

void $effect(Object effect) {
  final handler = _handler;
  $unbind(() {
    handler(effect);
  });
}

typedef $EffectHandler = void Function(Object effect);

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

$EffectHandler _handler;
