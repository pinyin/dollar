import 'package:dollar/dollar.dart';
import 'package:test/test.dart';

void main() {
  group('core', () {
    group('bind', () {
      test('should forward effects to handler', () {
        final effects = <_MockEffect>[];
        final func = $bind((_) {
          $effect((cursor) => _MockEffect(1, cursor));
          $effect((cursor) => _MockEffect(2, cursor));
        }, effects.add);
        expect(effects, []);
        func(null);
        expect(effects.map((e) => e.value), [1, 2]);
      });
      test('should create new ref context', () {
        final effects = <_MockEffect>[];
        final func = $bind((_) {
          $effect((cursor) => _MockEffect(1, cursor));
          $effect((cursor) => _MockEffect(2, cursor));
          $bind((_) {
            $effect((cursor) => _MockEffect(3, cursor));
            $effect((cursor) => _MockEffect(4, cursor));
          })(null);
        }, effects.add);
        expect(effects, []);
        func(null);
        expect(effects.map((e) => e.value), [1, 2, 3, 4]);
        effects.clear();
        func(null);
        expect(effects.map((e) => e.value), [1, 2, 3, 4]);
      });
    });
    group('cursor', () {
      test('should keep updates across calls', () {
        $Cursor<int> cursor;
        final func = $bind((_) {
          cursor = $cursor(() => 1);
          $cursor(() => 2);
        }, (effect) {});
        func(null);
        expect(cursor?.value, 1);
        cursor.value++;
        func(null);
        expect(cursor?.value, 2);
      });
    });
    group('if', () {
      test('should return value in path', () {
        final func = $bind((bool input) {
          return $if(input, () {
            return 1;
          }, orElse: () => 2);
        }, (effect) {});
        expect(func(true), 1);
        expect(func(false), 2);
      });
      test('should create separated ref context', () {
        $Cursor<int> a;
        $Cursor<int> b;
        final func = $bind((bool input) {
          a = $cursor(() => 1);
          b = $if(input, () {
            return $cursor(() => 2);
          }, orElse: () => $cursor(() => 3));
          a.value++;
          b.value--;
        }, (_) {});
        func(true);
        expect(a?.value, 2);
        expect(b?.value, 1);
        func(true);
        expect(a?.value, 3);
        expect(b?.value, 0);
        func(false);
        expect(a?.value, 4);
        expect(b?.value, 2);
        func(false);
        expect(a?.value, 5);
        expect(b?.value, 1);
      });
    });
  });

  group('extensions', () {
    group('ref', () {
      test('should keep reference to value', () {
        final refs = <$Ref>[];
        final func = $bind((value) {
          refs.add($ref(() => value));
        }, (_) {});
        func(1);
        func(2);
        expect(refs[0], refs[1]);
        expect(refs[0].value(), 2);
      });
    });

    group('var', () {
      test('should emit VarEffect', () {
        final effects = <$UpdateVar>[];
        final func = $bind((_) {
          return $var(() => 1);
        }, effects.add);
        var v = func(null);
        v.value = 2;
        expect(effects[0].to, 2);
        effects.clear();
        v = func(null);
        v.value = 3;
        expect(effects[0].to, 3);
      });
    });

    group('final', () {
      test('should keep value when second parameter is true', () {
        var value = 0;
        final func = $bind((keep) {
          return $final(() => ++value, keep);
        }, (_) {});
        expect(func(true), 1);
        expect(func(true), 1);
        expect(func(false), 2);
        expect(func(false), 3);
        expect(func(true), 3);
      });
    });

    group('prev', () {
      test('should provide previous value', () {
        final listeners = $Listeners();
        final func = $bind((value) {
          return $prev(value);
        }, $listenAt(listeners));
        expect(func(1), null);
        expect(func(2), 1);
        expect(func(3), 2);
      });
    });

    group('diff', () {
      test('should provide value and previous value to diff function', () {
        final listeners = $Listeners();
        final func = $bind((value) {
          return $diff(value, (prev, curr) => (prev ?? 0) + curr);
        }, $listenAt(listeners));
        expect(func(1), 1);
        expect(func(2), 3);
        expect(func(2), 4);
        expect(func(1), 3);
      });
    });

    group('scan', () {
      test('should compute value based on previous value', () {
        final func = $bind((skip) {
          return $scan((prev) => (prev ?? 0) + 1, skip);
        }, (_) {});
        expect(func(true), null);
        expect(func(false), 1);
        expect(func(false), 2);
        expect(func(true), 2);
        expect(func(true), 2);
      });
    });

    group('listen', () {
      test('should emit listener event', () {
        final effects = <$Effect>[];
        final listener = (int i) {
          return;
        };
        final func = $bind((_) {
          $listen(listener);
        }, effects.add);
        func(null);
        func(null);
        expect(effects.length, 2);
        expect(effects[0].at, effects[1].at);
      });
      test('should wrap callback into an effect', () {
        final effects = [];
        var result = 0;
        final listener = (int i) {
          final callCount = $cursor(() => 0);
          return callCount.value += i;
        };
        final func = $bind((_) {
          result = $listen(listener);
        }, effects.add);
        func(null);
        expect(effects[0] is $AddListener<int>, true);
        (effects[0] as $AddListener<int>).callback(1);
        func(null);
        expect(result, 1);
      });
    });

    group('fork', () {
      test('should run one instance of work', () {
        final effects = <$Effect>[];
        final listeners = $Listeners();
        var closeCount = 0;
        final listener = ($Cursor<int> value) {
          value.value ??= 0;
          value.value++;
          return () {
            closeCount++;
          };
        };
        var result = 0;
        final func = $bind((bool keep) {
          result = $fork(listener, keep);
        }, $combineHandlers([$listenAt(listeners), effects.add]));
        func(true);
        expect(result, 1);
        expect(closeCount, 0);
        func(false);
        expect(result, 2);
        expect(closeCount, 1);
        func(true);
        expect(result, 2);
        expect(closeCount, 1);
        (effects.where((e) => e is $AddListener<$End>).first
                as $AddListener<$End>)
            .callback($End());
        expect(result, 2);
        expect(closeCount, 2);
      });
    });
  });

  group('utils', () {
    group('combineHandlers', () {
      test('should call handlers in order', () {
        final results = <int>[];
        $combineHandlers([(_) => results.add(1), (_) => results.add(2)])(null);
        expect(results, [1, 2]);
      });
    });
    group('listenAt', () {
      test('should save listeners in Listeners', () {
        final listeners = $Listeners();
        final results = <int>[];
        final func = $bind((_) {
          $listen(results.add);
        }, $listenAt(listeners));
        func(null);
        listeners.trigger(1);
        listeners.trigger(2);
        expect(results, [1, 2]);
      });
    });
  });
}

class _MockEffect<T> implements $Effect {
  final $Cursor<T> at;
  final T value;

  _MockEffect(this.value, this.at);
}
