import 'package:dollar/dollar.dart';
import 'package:test/test.dart';

void main() {
  group('core', () {
    group('context & effect', () {
      test('should forward effects to handler', () {
        final effects = <dynamic>[];
        final Null Function() func = $context0(() {
          $effect(1);
          $effect(2);
        }, onEffect: ($EffectHandler? _) => effects.add);
        expect(effects, <dynamic>[]);
        func();
        expect(effects, [1, 2]);
      });

      test('should pass parent effect handler to child', () {
        final effects = <dynamic>[];
        final Null Function() func = $context0(() {
          $context0(() {
            $effect(1);
            $effect(2);
          }, onEffect: (p) => (o) => p?.call(o))();
        }, onEffect: (_) => effects.add);
        expect(effects, <dynamic>[]);
        func();
        expect(effects, [1, 2]);
      });
    });

    group('value', () {
      test('should keep value across calls', () {
        final func = $context0(() {
          final a = $value(() => 0);
          a.value++;
          return a.value;
        });
        expect(func(), 1);
        expect(func(), 2);
        expect(func(), 3);
      });

      test('should keep value across async calls', () async {
        final func = $context0(() async {
          final a = $value(() => 0);
          await Future<dynamic>.value();
          a.value++;
          return a.value;
        });
        expect(await func(), 1);
        expect(await func(), 2);
        expect(await func(), 3);
      });
    });

    group('fold & merge', () {
      test('should provide multiple contexts based on key', () {
        final func = $context1((int key) {
          $fork(key);
          final result = $value(() => 0);
          result.value++;
          return result.value;
        });

        expect(func(0), 1);
        expect(func(1), 1);
        expect(func(0), 2);
        expect(func(2), 1);
      });
    });
  });

  group('extensions', () {
    group('Method', () {
      final obj = _BoundObject();
      test('should provide a dollar context for each method', () {
        expect(obj.inc(0), 0);
        expect(obj.inc(2), 2);
        expect(obj.inc(), 3);
        expect(obj.dec(), 0);
        expect(obj.dec(3), 3);
        expect(obj.dec(), 2);
        expect(obj.inc(), 4);
      });
    });

    group('ref', () {
      test('should keep reference to value', () {
        final refs = <$Ref>[];
        final Null Function(int) func = $context1((int value) {
          refs.add((() => value).$ref);
        });
        func(1);
        func(2);
        expect(refs[0], refs[1]);
        expect(refs[0].value(), 2);
      });
    });

    group('isInit', () {
      test('should return true on first run then false forever', () {
        final func = $context0(() {
          return $isInit();
        });
        expect(func(), true);
        expect(func(), false);
        expect(func(), false);
        expect(func(), false);
      });
    });

    group('var', () {
      test('should emit VarEffect on value update', () {
        final effects = <$VarUpdated>[];
        final func = $context0(() {
          return $var(() => 1);
        }, onEffect: (_) {
          return (effect) => effect is $VarUpdated ? effects.add(effect) : null;
        });
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
        final func = $context0(() {
          return $final(() => ++value);
        });
        expect(func(), 1);
        expect(func(), 1);
      });
    });

    group('cache', () {
      test('should return cached value iff second parameter is true', () {
        var value = 0;
        final func = $context1((bool keep) {
          return $cache(() => ++value, keep);
        });
        expect(func(true), 1);
        expect(func(true), 1);
        expect(func(false), 2);
        expect(func(false), 3);
        expect(func(true), 3);
      });
    });

    group('prev', () {
      test('should provide previous value', () {
        final func = $context1((Object value) {
          return value.$prev;
        });
        expect(func(1), null);
        expect(func(1), 1);
        expect(func(2), 1);
        expect(func(3), 2);
      });
    });

    group('distinct', () {
      test('should return last non-equal value', () {
        final func = $context1((int value) {
          return $distinct(value, (int? a, int b) => a! % 2 == b % 2)!;
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

    group('interpolate', () {
      test('should provide value and previous value to interpolate function',
          () {
        final func = $context1((int value) {
          return $interpolate(
              value, (int? prev, int curr) => (prev ?? 0) + curr);
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
        final func = $context1((int value) {
          return $aggregate(
              value, (int? prev, int curr) => (prev ?? 0) + curr)!;
        });
        expect(func(1), 1);
        expect(func(2), 3);
        expect(func(2), 5);
        expect(func(1), 6);
      });
    });

    group('generate', () {
      test('should compute value based on previous value', () {
        final func = $context0(() {
          return $generate((int? prev) => (prev ?? 0) + 1)!;
        });
        expect(func(), 1);
        expect(func(), 2);
        expect(func(), 3);
      });
    });

    group('memo', () {
      test('should recompute when dependencies changed', () {
        var deps = [1, 2];
        final func = $context0(() {
          var init = $value(() => 0);
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
      test('should support Null', () {
        $context0(() {
          $memo(() {}, <int>[1]);
        });
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
              parent!(_);
            });
        handlers.add((parent) => (_) {
              results.add(2);
            });
        handlers.add((parent) => (_) {
              results.add(3);
              parent!(_);
            });
        $combineHandlers(handlers)(null)(null);
        expect(results, [3, 2]);
      });
    });
    group('onUpdateVar', () {
      test('should call callback on UpdateVar effect', () {
        final results = <dynamic>[];
        final func = $context0(() {
          return $var(() => 0);
        }, onEffect: (_) => results.add);
        func().value = 0;
        func().value = 1;
        func().value = 2;
        expect(results.length, 3);
      });
    });
  });
}

class _BoundObject with $Method {
  int? inc([int? set]) {
    return $method(inc, () {
      final value = $value(() => -1);
      value.value++;
      if (set != null) value.value = set;
      return value.value;
    });
  }

  int? dec([int? set]) {
    return $method(dec, () {
      final value = $value(() => 1);
      value.value--;
      if (set != null) value.value = set;
      return value.value;
    });
  }
}
