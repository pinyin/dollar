import 'package:dollar/dollar.dart';
import 'package:test/test.dart';

void main() {
  group('core', () {
    group('bind', () {
      test('should forward effects to handler', () {
        final effects = [];
        final func = $bind0(() {
          $raise(1);
          $raise(2);
        }, (_) => effects.add);
        expect(effects, []);
        func();
        expect(effects, [1, 2]);
      });
      test('should create new cursor context', () {
        final effects = [];
        final func = $bind0(() {
          $raise(1);
          $raise(2);
          $bind0(() {
            $raise(3);
            $raise(4);
          })();
        }, (_) => effects.add);
        expect(effects, []);
        func();
        expect(effects, [1, 2, 3, 4]);
        effects.clear();
        func();
        expect(effects, [1, 2, 3, 4]);
      });
    });

    group('isolate', () {
      test('should hide context form callback', () {
        final func = $bind0(() {
          $raise(1);
          $isolate(() {
            $raise(2);
          });
        });
        expect(func, throwsA(TypeMatcher<NoSuchMethodError>()));
      });
      test('should keep return value of inner function', () {
        final func = $bind1((value) {
          return $isolate(() {
            return value;
          });
        });
        expect(func(1), 1);
        expect(func(3), 3);
      });
    });

    group('cursor', () {
      test('should keep value across calls', () {
        $Cursor<int> cursor;
        final func = $bind0(() {
          cursor = $cursor(() => 1);
          $cursor(() => 2);
        });
        func();
        expect(cursor?.value, 1);
        cursor.value++;
        func();
        expect(cursor?.value, 2);
      });
    });

    group('fork', () {
      test('should provide multiple contexts based on key', () {
        final func = $bind1((key) {
          return $fork(key, () {
            return $cursor(() => 0);
          });
        });
        func(0).value++;
        func(2).value = 2;
        expect(func(0).value, 1);
        expect(func(1).value, 0);
        expect(func(2).value, 2);
      });
    });

    group('defer', () {
      test('should run callback after function exits', () {
        int runCount = 0;
        int deferCount = 0;
        final func = $bind1((bool shouldThrow) {
          $defer(() {
            deferCount++;
          });
          if (shouldThrow) throw 1;
          runCount++;
        });
        func(false);
        expect(runCount, 1);
        expect(deferCount, 1);
        expect(() => func(true), throwsA(1));
        expect(runCount, 1);
        expect(deferCount, 2);
        func(false);
        expect(runCount, 2);
        expect(deferCount, 3);
      });
    });

    group('raise', () {
      test('should delegate call to handler', () {
        final effects = [];
        final func = $bind1((int value) {
          return $raise(value);
        }, (_) {
          return (effect) {
            effects.add(effect);
            if (effect is int) return effect + 1;
            return null;
          };
        });
        expect(func(0), 1);
        expect(func(1), 2);
        expect(effects, [0, 1]);
      });
    });
  });

  group('extensions', () {
    group('if', () {
      test('should call function by condition', () {
        final func = $bind1((bool input) {
          return $if(input, () {
            return 1;
          }, orElse: () => 2);
        });
        expect(func(true), 1);
        expect(func(false), 2);
      });
      test('should create separated cursor context', () {
        $Cursor<int> a;
        $Cursor<int> b;
        final func = $bind1((bool input) {
          a = $cursor(() => 1);
          b = $if(input, () {
            return $cursor(() => 2);
          }, orElse: () => $cursor(() => 3));
          a.value++;
          b.value--;
        });
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

    group('switch', () {
      test('should call function by value', () {
        final values = [];
        final func = $bind1((Object input) {
          return $switch(input, {
            'a': () => values.add(1),
            'b': () => values.add(2),
            'c': () => values.add(3),
            'd': () => values.add(4),
          });
        });
        func('d');
        func('a');
        func('c');
        func('b');
        func('e');
        func('a');
        expect(values, [4, 1, 3, 2, 1]);
      });
    });

    group('unless', () {
      test('should call function when condition is not matched', () {
        final func = $bind1((bool input) {
          return $unless(input, () {
            return 1;
          });
        });
        expect(func(true), null);
        expect(func(false), 1);
      });
    });

    group('ref', () {
      test('should keep reference to value', () {
        final refs = <$Ref>[];
        final func = $bind1((value) {
          refs.add($ref(() => value));
        });
        func(1);
        func(2);
        expect(refs[0], refs[1]);
        expect(refs[0].value(), 2);
      });
    });

    group('var', () {
      test('should emit VarEffect on value update', () {
        final effects = <$VarUpdated>[];
        final func = $bind0(() {
          return $var(() => 1);
        }, (_) => effects.add);
        var v = func();
        v.value = 2;
        expect(effects.length, 1);
        effects.clear();
        v = func();
        v.value = 3;
        expect(effects.length, 1);
      });
    });

    group('final', () {
      test('should keep value', () {
        var value = 0;
        final func = $bind0(() {
          return $final(() => ++value);
        });
        expect(func(), 1);
        expect(func(), 1);
      });
    });

    group('cache', () {
      test('should return cached value iff second parameter is true', () {
        var value = 0;
        final func = $bind1((keep) {
          return $cache(() => ++value, keep);
        });
        expect(func(true), 1);
        expect(func(true), 1);
        expect(func(false), 2);
        expect(func(false), 3);
        expect(func(true), 3);
      });
      test('should clean cache when inner var is updated', () {
        var count = 0;
        $Var variable;
        final func = $bind0(() {
          return $cache(() {
            count++;
            variable = $var(() => 1);
            return variable;
          }, true);
        });
        func();
        expect(count, 1);
        func();
        expect(count, 1);
        variable.value++;
        func();
        expect(count, 2);
        func();
        expect(count, 2);
        variable.value++;
        func();
        expect(count, 3);
      });
    });

    group('prev', () {
      test('should provide previous value', () {
        final func = $bind1((value) {
          return $prev(value);
        });
        expect(func(1), null);
        expect(func(1), 1);
        expect(func(2), 1);
        expect(func(3), 2);
      });
    });

    group('distinct', () {
      test('should return last non-equal value', () {
        final func = $bind1((value) {
          return $distinct(value, (a, b) => a % 2 == b % 2);
        });
        expect(func(1), 1);
        expect(func(1), 1);
        expect(func(2), 2);
        expect(func(4), 2);
        expect(func(6), 2);
        expect(func(7), 7);
        expect(func(8), 8);
      });
    });

    group('equals', () {
      test('should return the identicality of value & previous value', () {
        final func = $bind1((value) {
          return $equals(value);
        });
        expect(func(1), false);
        expect(func(2), false);
        expect(func(2), true);
        expect(func(3), false);
      });
    });

    group('identical', () {
      test('should return the identicality of value & previous value', () {
        final func = $bind1((value) {
          return $identical(value);
        });
        expect(func(1), false);
        expect(func(2), false);
        expect(func(2), true);
        expect(func(3), false);
      });
    });

    group('shallowEquals', () {
      test('should return the shallow identicality of value & previous value',
          () {
        final func = $bind1((value) {
          return $shallowEquals(value);
        });
        expect(func([1, 2]), false);
        expect(func([1, 2]), true);
        expect(func([1]), false);
        expect(func([3]), false);
      });
    });

    group('while', () {
      test('should run effect as long as condition returns true', () {
        final func = $bind1((int loop) {
          return $while(() => loop > 0, () {
            loop--;
            return ++$cursor(() => 0).value;
          });
        });
        expect(func(2), 2);
        expect(func(3), 5);
        expect(func(4), 9);
      });
    });

    group('interpolate', () {
      test('should provide value and previous value to interpolate function',
          () {
        final func = $bind1((value) {
          return $interpolate(value, (prev, curr) => (prev ?? 0) + curr);
        });
        expect(func(1), 1);
        expect(func(2), 3);
        expect(func(2), 4);
        expect(func(1), 3);
      });
    });

    group('aggregate', () {
      test('should provide value and aggregated value to aggregate function',
          () {
        final func = $bind1((value) {
          return $aggregate(value, (prev, curr) => (prev ?? 0) + curr);
        });
        expect(func(1), 1);
        expect(func(2), 3);
        expect(func(2), 5);
        expect(func(1), 6);
      });
    });

    group('generate', () {
      test('should compute value based on previous value', () {
        final func = $bind0(() {
          return $generate((prev) => (prev ?? 0) + 1);
        });
        expect(func(), 1);
        expect(func(), 2);
        expect(func(), 3);
      });
    });

    group('memo', () {
      test('should recompute when dependencies changed', () {
        var deps = [1, 2];
        final func = $bind0(() {
          var init = $cursor(() => 0);
          return $memo(() => ++init.value, deps);
        });
        expect(func(), 1);
        expect(func(), 1);
        deps = [2, 2];
        expect(func(), 2);
        expect(func(), 2);
        deps = [2, 3];
        expect(func(), 3);
      });
    });

    group('listen', () {
      test('should emit listener event', () {
        final effects = [];
        final listener = (int i) {
          return;
        };
        final func = $bind0(() {
          $listen(listener);
        }, (_) => effects.add);
        func();
        func();
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
        final func = $bind0(() {
          $listen(listener);
        }, $onListened(listeners));
        func();
        listeners.trigger(1);
        func();
        expect(result, 1);
      });
    });

    group('async', () {
      test('should run one instance of work', () {
        final listeners = $Listeners();
        var closeCount = 0;
        var result = 0;
        final func = $bind0(() {
          $async(() {
            result++;
            return () => closeCount++;
          });
        }, $onListened(listeners));
        func();
        expect(result, 1);
        expect(closeCount, 0);
        func();
        expect(result, 2);
        expect(closeCount, 1);
        listeners.trigger($ContextTerminated());
        expect(result, 2);
        expect(closeCount, 2);
      });
    });

    group('effect', () {
      test('should run one instance of work when deps are updated', () {
        final listeners = $Listeners();
        var closeCount = 0;
        var result = 0;
        final func = $bind1((deps) {
          $effect(() {
            result++;
            return () => closeCount++;
          }, deps);
        }, $onListened(listeners));
        func([0, 1]);
        expect(result, 1);
        expect(closeCount, 0);
        func([0, 1]);
        expect(result, 1);
        expect(closeCount, 0);
        func([1, 1]);
        expect(result, 2);
        expect(closeCount, 1);
        listeners.trigger($ContextTerminated());
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
        final func = $bind0(() {
          $listen(results.add);
        }, $onListened(listeners));
        func();
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
        final results = <$VarUpdated>[];
        final func = $bind0(() {
          return $var(() => 0);
        }, $onVarUpdated(results.add));
        func().value = 0;
        func().value = 1;
        func().value = 2;
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
