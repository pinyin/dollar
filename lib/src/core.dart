import 'dart:async';
import 'dart:collection';

// todo refactor with WeakReference & Finalizer

dynamic $(Function func, {$EffectHandlerCreator? onEffect}) {
  final values = LinkedList<_LinkedValue>();
  return _Context(func, values, onEffect?.call(_handler));
}

$Value<T> $value<T>(T init()) {
  return _cursors!.last.next<T>(init);
}

void $fork(dynamic tag) {
  final values = $value(() => <dynamic, LinkedList<_LinkedValue>>{});
  values.value[tag] ??= LinkedList<_LinkedValue>();
  _cursors!.add(_Cursor(values.value[tag]!));
}

void $merge() {
  _cursors!.removeLast();
}

void $effect(dynamic effect) {
  final handler = _handler;
  return runZoned<dynamic>(
    () {
      handler?.call(effect);
    },
    zoneValues: <_HooksZoneValue, dynamic>{
      _HooksZoneValue.handler: null,
      _HooksZoneValue.cursors: null,
    },
  );
}

typedef $EffectHandlerCreator = $EffectHandler Function($EffectHandler? parent);
typedef $EffectHandler = void Function(Object? effect);

class $Value<T> {
  T get value => _value;

  set value(T newValue) => _value = newValue;

  T get() => _value;

  T set(T newValue) => value = newValue;

  T _value;

  $Value(this._value);
}

class _Context<T extends Function> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return runZoned<dynamic>(
      () => Function.apply(
          _func, invocation.positionalArguments, invocation.namedArguments),
      zoneValues: <_HooksZoneValue, dynamic>{
        _HooksZoneValue.handler: _handler,
        _HooksZoneValue.cursors: [_Cursor(_values)],
      },
    );
  }

  final T _func;
  final LinkedList<_LinkedValue> _values;
  final $EffectHandler? _handler;

  _Context(this._func, this._values, this._handler);
}

class _Cursor {
  $Value<T> next<T>(T Function() init) {
    if (_entry == null) {
      if (_context.isEmpty) {
        _context.add(_LinkedValue($Value<T>(init())));
      }
      _entry = _context.first;
    } else {
      if (_entry!.next == null) {
        assert(_entry == _context.last);
        _context.add(_LinkedValue($Value<T>(init())));
      }
      _entry = _entry!.next;
    }
    return _entry!.value as $Value<T>;
  }

  void reset() => _entry = null;

  _LinkedValue? _entry;
  final LinkedList<_LinkedValue> _context;

  _Cursor? forkedFrom;

  _Cursor(this._context);
}

class _LinkedValue extends LinkedListEntry<_LinkedValue> {
  final $Value value;

  _LinkedValue(this.value);
}

List<_Cursor>? get _cursors =>
    Zone.current[_HooksZoneValue.cursors] as List<_Cursor>?;

$EffectHandler? get _handler =>
    Zone.current[_HooksZoneValue.handler] as $EffectHandler?;

enum _HooksZoneValue { handler, cursors }
