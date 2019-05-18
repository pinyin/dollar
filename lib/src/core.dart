import 'package:collection/collection.dart';

R Function(T) $handle<T, R>(R func(T params), [$EffectHandler handler]) {
  assert(_handler != null || handler != null);
  assert(_handler == null || handler == null);
  handler ??= _handler;
  func = $(func);

  return (T params) {
    // TODO support arbitrary parameters
    // TODO improve performance

    final prevHandler = _handler;
    _handler = handler;

    final result = func(params);

    assert(identical(_handler, handler));
    _handler = prevHandler;

    return result;
  };
}

$Effects<T, R> $<T, R>($Effects<T, R> effects) {
  final _Context context =
      _context == null ? _Context() : $ref(() => _Context()).value;
  return (T params) {
    final prevContext = _context;
    _context = context;
    _context.cursorReset();

    final result = effects(params);

    assert(identical(_context, context));
    _context = prevContext;

    return result;
  };
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

abstract class $Effect {}

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
  set cursor($Ref status) => _cursor == _cursors.length
      ? _cursors.addLast(status)
      : _cursors[_cursor] = status;

  $Ref get cursor =>
      _cursors.length > _cursor ? _cursors.elementAt(_cursor) : null;

  void cursorNext() => _cursor++;

  void cursorReset() => _cursor = 0;

  int _cursor = 0;
  QueueList<$Ref> _cursors = QueueList();
}

_Context _context;

$EffectHandler _handler;

typedef $Effects<T, R> = R Function(T);
