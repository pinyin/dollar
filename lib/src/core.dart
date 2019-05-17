import 'package:collection/collection.dart';

T Function(R) $handle<T, R>(T func(R params), $EffectHandler handler) {
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

$Ref<T> $ref<T>(T init()) {
  final result = _cursors.cursor ??= _$RefImpl<T>()..value = init();
  _cursors.cursorNext();
  return result;
}

T $if<T>(bool condition, T then(), {T orElse()}) {
  final thenCursors = $ref(() => _Cursors());
  final orElseCursors = $ref(() => _Cursors());

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

class _Cursors {
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

_Cursors _cursors;

$EffectHandler _handler;
