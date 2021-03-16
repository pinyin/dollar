import 'dart:async';
import 'dart:collection';

dynamic $bind<T extends Function>(T func,
    [$EffectHandlerCreator? createHandler]) {
  final isInAnotherBindFunction = _handler != null;
  final $BoundFunction boundFunction = isInAnotherBindFunction
      ? ($property(() => $BoundFunction()..context = _Context())).value
      : ($BoundFunction()..context = _Context());

  final handler =
      (createHandler ?? _createDefaultHandler)(_handler ?? (effect) {});

  handler($Reset._(() => boundFunction..context = _Context()));

  return boundFunction
    ..handler = handler
    ..func = func;
}

final $EffectHandlerCreator _createDefaultHandler =
    (parent) => (effect) => parent!(effect);

enum _HooksZoneValue { handler, cursor }

class $BoundFunction implements Function {
  late Function func;
  late _Context context;
  $EffectHandler? handler;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return runZoned<dynamic>(
      () => Function.apply(
          func, invocation.positionalArguments, invocation.namedArguments),
      zoneValues: <_HooksZoneValue, dynamic>{
        _HooksZoneValue.handler: handler,
        _HooksZoneValue.cursor: context.cursor,
      },
    );
  }
}

T $isolate<T>(T func()) {
  return runZoned<T>(
    func,
    zoneValues: <_HooksZoneValue, dynamic>{
      _HooksZoneValue.handler: null,
      _HooksZoneValue.cursor: null,
    },
  );
}

$Property<T> $property<T>(T init()) {
  final cursor = _cursor!.next<T>(init);
  return cursor;
}

T $switch<T>(Object key, T Function() logic) {
  final contexts = $property(() => Map<Object, _Context>()).value;
  return runZoned(
    () => logic.call(),
    zoneValues: <_HooksZoneValue, dynamic>{
      _HooksZoneValue.handler: _handler,
      _HooksZoneValue.cursor: (contexts[key] ??= _Context()).cursor,
    },
  );
  // TODO allow cleanup
}

void $raise(Object effect) {
  return runZoned<dynamic>(
    () {
      final handler = _handler;
      if (handler == null) throw $NotInContext();
      handler(effect);
    },
    zoneValues: <_HooksZoneValue, dynamic>{
      _HooksZoneValue.handler: _handler,
      _HooksZoneValue.cursor: null,
    },
  );
}

class $NotInContext extends Error {}

class $Reset {
  void call() {
    _logic();
  }

  final void Function() _logic;

  $Reset._(this._logic);
}

typedef $EffectHandler = void Function(Object? effect);

typedef $EffectHandlerCreator = $EffectHandler Function($EffectHandler? parent);

class $Property<T> {
  T get value => _value;

  set value(T newValue) => _value = newValue;

  T get() => _value;

  T set(T newValue) => value = newValue;

  T _value;
  $Property(this._value);
}

class _Context {
  // TODO move handlers here
  _Cursor get cursor => _Cursor(this._cursors);

  final _cursors = LinkedList<_LinkedProperty>();
}

class _Cursor {
  $Property<T> next<T>(T Function() init) {
    if (_entry == null) {
      if (_properties.isEmpty)
        _properties.add(_LinkedProperty($Property<T>(init())));
      _entry = _properties.first;
    } else {
      if (_entry!.next == null) {
        assert(_entry == _properties.last);
        _properties.add(_LinkedProperty($Property<T>(init())));
      }
      _entry = _entry!.next;
    }
    return _entry!.value as $Property<T>;
  }

  _LinkedProperty? _entry;
  final LinkedList<_LinkedProperty> _properties;

  _Cursor(this._properties);
}

class _LinkedProperty extends LinkedListEntry<_LinkedProperty> {
  final $Property value;

  _LinkedProperty(this.value);
}

_Cursor? get _cursor => Zone.current[_HooksZoneValue.cursor] as _Cursor?;

$EffectHandler? get _handler =>
    Zone.current[_HooksZoneValue.handler] as $EffectHandler?;

class $Exception {
  final Object error;
  final StackTrace stack;

  $Exception(this.error, this.stack);
}
