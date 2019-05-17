import 'package:dollar/dollar.dart';
import 'package:dollar/src/effects.dart';
import 'package:test/test.dart';

void main() {
  group('core', () {
    group('handle', () {
      test('should forward effects to handler', () {
        final effects = <_MockEffect>[];
        final func = $handle((_) {
          $effect(_MockEffect($ref(() => 1)));
          $effect(_MockEffect($ref(() => 2)));
        }, effects.add);
        expect(effects, []);
        func(null);
        expect(effects.map((e) => e.at.value), [1, 2]);
      });
      test('should create new ref context', () {
        final effects = <_MockEffect>[];
        final func = $handle((_) {
          $effect(_MockEffect($ref(() => 1)));
          $effect(_MockEffect($ref(() => 2)));
          $handle((_) {
            $effect(_MockEffect($ref(() => 3)));
            $effect(_MockEffect($ref(() => 4)));
          })(null);
        }, effects.add);
        expect(effects, []);
        func(null);
        expect(effects.map((e) => e.at.value), [1, 2, 3, 4]);
        effects.clear();
        func(null);
        expect(effects.map((e) => e.at.value), [1, 2, 3, 4]);
      });
    });
    group('ref', () {
      test('should keep updates across calls', () {
        $Ref<int> ref;
        final func = $handle((_) {
          ref = $ref(() => 1);
          $ref(() => 2);
        }, (effect) {});
        func(null);
        expect(ref?.value, 1);
        ref.value++;
        func(null);
        expect(ref?.value, 2);
      });
    });
    group('if', () {
      test('should return value in path', () {
        final func = $handle((bool input) {
          return $if(input, () {
            return 1;
          }, orElse: () => 2);
        }, (effect) {});
        expect(func(true), 1);
        expect(func(false), 2);
      });
      test('should create separated ref context', () {
        $Ref<int> a;
        $Ref<int> b;
        final func = $handle((bool input) {
          a = $ref(() => 1);
          b = $if(input, () {
            return $ref(() => 2);
          }, orElse: () => $ref(() => 3));
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

  group('effects', () {
    group('var', () {
      test('should emit VarEffect', () {
        final effects = <$VarUpdateEffect>[];
        final func = $handle((_) {
          return $var(() => 1);
        }, effects.add);
        var v = func(null);
        v.value = 2;
        expect(effects[0].from, 1);
        expect(effects[0].to, 2);
        effects.clear();
        v = func(null);
        v.value = 3;
        expect(effects[0].from, 2);
        expect(effects[0].to, 3);
      });
    });

    group('scan', () {
      test('should run work when keys are updated', () {
        int runCount = 0;
        $Ref keyRef;
        final func = $handle((_) {
          keyRef = $ref(() => 0);
          $scan((_) {
            return runCount++;
          }, [keyRef.value]);
        }, (_) {});
        func(null);
        expect(runCount, 1);
        func(null);
        expect(runCount, 1);
        keyRef.value++;
        func(null);
        expect(runCount, 2);
        func(null);
        expect(runCount, 2);
      });
      test('should provide value to next scan', () {
        int fibonacci = 0;
        final func = $handle((_) {
          return $scan<int>((prev) {
            prev ??= 1;
            return prev + fibonacci;
          }, [fibonacci]);
        }, (_) {});
        fibonacci = func(null);
        expect(fibonacci, 1);
        fibonacci = func(null);
        expect(fibonacci, 2);
      });
    });

    group('listen', () {
      test('should emit listener event', () {
        final effects = [];
        final listener = (int i) {
          return;
        };
        final func = $handle((_) {
          $listen(listener);
        }, effects.add);
        func(null);
        func(null);
        expect(effects.length, 1);
        expect(effects[0] is $ListenerAddedEffect<int>, true);
      });
      test('should wrap callback into an effect', () {
        final effects = [];
        var result = 0;
        final listener = (int i) {
          final callCount = $ref(() => 0);
          return callCount.value += i;
        };
        final func = $handle((_) {
          result = $listen(listener);
        }, effects.add);
        func(null);
        func(null);
        expect(effects.length, 1);
        expect(effects[0] is $ListenerAddedEffect<int>, true);
        (effects[0] as $ListenerAddedEffect<int>).callback(1);
        func(null);
        expect(result, 1);
        expect(effects.length, 1);
        (effects[0] as $ListenerAddedEffect<int>).callback(1);
        func(null);
        expect(result, 2);
        expect(effects.length, 1);
      });
    });
  });
}

class _MockEffect<T> implements $Effect {
  final $Ref<T> at;

  _MockEffect(this.at);
}
