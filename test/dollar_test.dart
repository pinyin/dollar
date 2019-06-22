import 'package:dollar/dollar.dart';
import 'package:test/test.dart';

void main() {
  group('core', () {
    group('bind', () {
      test('should forward effects to handler', () {
        final effects = [];
        final func = $bind((_) {
          $effect(1);
          $effect(2);
        }, (_) => effects.add);
        expect(effects, []);
        func(null);
        expect(effects, [1, 2]);
      });
      test('should create new ref context', () {
        final effects = [];
        final func = $bind((_) {
          $effect(1);
          $effect(2);
          $bind((_) {
            $effect(3);
            $effect(4);
          })(null);
        }, (_) => effects.add);
        expect(effects, []);
        func(null);
        expect(effects, [1, 2, 3, 4]);
        effects.clear();
        func(null);
        expect(effects, [1, 2, 3, 4]);
      });
      test('should create new context iff handler is not null', () {
        final func = $bind((branch) {
          if (branch) {
            $bind((_) {
              $cursor(() => 1);
            }, (_) => (_) {})(null);
          }
          $cursor(() => 'a');
        }, $emptyHandler);
        func(true);
        func(false);
        func(true);
      });
    });
    group('cursor', () {
      test('should keep updates across calls', () {
        $Cursor<int> cursor;
        final func = $bind((_) {
          cursor = $cursor(() => 1);
          $cursor(() => 2);
        }, $emptyHandler);
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
        }, $emptyHandler);
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
        }, $emptyHandler);
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
        }, $emptyHandler);
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
        }, (_) => effects.add);
        var v = func(null);
        v.value = 2;
        expect(effects.length, 1);
        effects.clear();
        v = func(null);
        v.value = 3;
        expect(effects.length, 1);
      });
    });

    group('final', () {
      test('should keep value', () {
        var value = 0;
        final func = $bind((_) {
          return $final(() => ++value);
        }, $emptyHandler);
        expect(func(null), 1);
        expect(func(null), 1);
      });
    });

    group('cache', () {
      test('should return cached value iff second parameter is true', () {
        var value = 0;
        final func = $bind((keep) {
          return $cache(() => ++value, keep);
        }, $emptyHandler);
        expect(func(true), 1);
        expect(func(true), 1);
        expect(func(false), 2);
        expect(func(false), 3);
        expect(func(true), 3);
      });
    });

    group('prev', () {
      test('should provide previous value', () {
        final func = $bind((value) {
          return $prev(value);
        }, $emptyHandler);
        expect(func(1), null);
        expect(func(2), 1);
        expect(func(3), 2);
      });
    });

    group('equals', () {
      test('should return the identicality of value & previous value', () {
        final func = $bind((value) {
          return $equals(value);
        }, $emptyHandler);
        expect(func(1), false);
        expect(func(2), false);
        expect(func(2), true);
        expect(func(3), false);
      });
    });

    group('identical', () {
      test('should return the identicality of value & previous value', () {
        final func = $bind((value) {
          return $identical(value);
        }, $emptyHandler);
        expect(func(1), false);
        expect(func(2), false);
        expect(func(2), true);
        expect(func(3), false);
      });
    });

    group('diff', () {
      test('should provide value and previous value to diff function', () {
        final func = $bind((value) {
          return $diff(value, (prev, curr) => (prev ?? 0) + curr);
        }, $emptyHandler);
        expect(func(1), 1);
        expect(func(2), 3);
        expect(func(2), 4);
        expect(func(1), 3);
      });
    });

    group('scan', () {
      test('should compute value based on previous value', () {
        final func = $bind((_) {
          return $scan((prev) => (prev ?? 0) + 1);
        }, $emptyHandler);
        expect(func(null), 1);
        expect(func(null), 2);
        expect(func(null), 3);
      });
    });

    group('memo', () {
      test('should recompute when dependencies changed', () {
        var deps = [1, 2];
        final func = $bind((_) {
          var init = $cursor(() => 0);
          return $memo(() => ++init.value, deps);
        }, $emptyHandler);
        expect(func(null), 1);
        expect(func(null), 1);
        deps = [2, 2];
        expect(func(null), 2);
        expect(func(null), 2);
        deps = [2, 3];
        expect(func(null), 3);
      });
    });

    group('listen', () {
      test('should emit listener event', () {
        final effects = [];
        final listener = (int i) {
          return;
        };
        final func = $bind((_) {
          $listen(listener);
        }, (_) => effects.add);
        func(null);
        func(null);
        expect(effects.length, 2);
        expect(effects[0].at, effects[1].at);
      });
      test('should wrap callback into an effect', () {
        final listeners = $Listeners();
        var result = 0;
        final listener = (int i) {
          final callCount = $cursor(() => 0);
          result = callCount.value += i;
        };
        final func = $bind((_) {
          $listen(listener);
        }, $listenAt(listeners));
        func(null);
        listeners.trigger(1);
        func(null);
        expect(result, 1);
      });
    });

    group('fork', () {
      test('should run one instance of work', () {
        final listeners = $Listeners();
        var closeCount = 0;
        var result = 0;
        final func = $bind((_) {
          $fork(() {
            result++;
            return () => closeCount++;
          });
        }, $listenAt(listeners));
        func(null);
        expect(result, 1);
        expect(closeCount, 0);
        func(null);
        expect(result, 2);
        expect(closeCount, 1);
        listeners.trigger($End());
        expect(result, 2);
        expect(closeCount, 2);
      });
    });
  });

  group('utils', () {
    group('combineHandlers', () {
      test('should call last handler', () {
        final results = <int>[];
        $combineHandlers([
          (_) => (_) => results.add(1),
          (_) => (_) => results.add(2),
        ])(null)(null);
        expect(results, [2]);
      });
      test('should provide lefter handler as parent of right handler', () {
        final results = <int>[];
        final handlers = <$EffectHandlerCreator>[];
        handlers.add((parent) => (_) {});
        handlers.add((parent) => (_) {
              results.add(1);
              parent(_);
            });
        handlers.add((parent) => (_) {
              results.add(2);
            });
        handlers.add((parent) => (_) {
              results.add(3);
              parent(_);
            });
        $combineHandlers(handlers)(null)(null);
        expect(results, [3, 2]);
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
      test('should be able to trigger event without listener', () {
        final listeners = $Listeners();
        listeners.trigger(1);
        listeners.trigger(2);
      });
    });
    group('onUpdateVar', () {
      test('should call callback on UpdateVar effect', () {
        final results = <$UpdateVar>[];
        final func = $bind((_) {
          return $var(() => 0);
        }, $onUpdateVar(results.add));
        func(null).value = 0;
        func(null).value = 1;
        func(null).value = 2;
        expect(results.length, 3);
        expect(results[0].from, 0);
        expect(results[0].to, 0);
        expect(results[1].from, 0);
        expect(results[1].to, 1);
        expect(results[2].from, 1);
        expect(results[2].to, 2);
      });
    });
  });
}
