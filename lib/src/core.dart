import 'package:collection/collection.dart';

T Function(R) $handle<T, R>(T func(R params), void handler(Object effect)) {
  assert(_cursors == null);
  final cursors = _Cursors();

  void Function(Object) prevHandler;

  return (R params) {
    // TODO support arbitrary parameters
    _cursors = cursors;
    _cursors.cursorReset();

    prevHandler = _handler;
    _handler = handler;

    final result = func(params);
    assert(identical(_handler, handler));
    _handler = prevHandler;

    assert(identical(_cursors, cursors));
    _cursors = null;

    return result;
  };
}

$Cursor<T> $cursor<T>(T init()) {
  final result = _cursors.cursor ??= $Cursor<T>()..value = init();
  _cursors.cursorNext();
  return result;
}

T $if<T>(bool condition, T then(), {T orElse()}) {
  final thenCursors = $cursor(() => _Cursors());
  final orElseCursors = $cursor(() => _Cursors());

  T result;

  final prevCursors = _cursors;
  if (condition) {
    _cursors = thenCursors.value;
    _cursors.cursorReset();
    result = then();
    assert(identical(_cursors, thenCursors.value));
  } else if (orElse != null) {
    _cursors = orElseCursors.value;
    _cursors.cursorReset();
    result = orElse();
    assert(identical(_cursors, orElseCursors.value));
  }
  _cursors = prevCursors;

  return result;
}

void $effect(Object effect) {
  _handler(effect);
}

class $Cursor<T> {
  T get value => _value;
  set value(T newValue) => _value = newValue;

  T get() => value;
  T set(T newValue) => value = newValue;

  T _value;
}

class _Cursors {
  set cursor($Cursor status) => _cursor == _cursors.length
      ? _cursors.addLast(status)
      : _cursors[_cursor] = status;

  $Cursor get cursor =>
      _cursors.length > _cursor ? _cursors.elementAt(_cursor) : null;

  void cursorNext() => _cursor++;

  void cursorReset() => _cursor = 0;

  int _cursor = 0;
  QueueList<$Cursor> _cursors = QueueList();
}

_Cursors _cursors;

void Function(Object effect) _handler;
