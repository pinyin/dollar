import 'package:dollar/dollar.dart';
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
    });
    group('cursor', () {
      test('should keep updates across calls', () {
        $Ref<int> cursor;
        final func = $handle((_) {
          cursor = $ref(() => 1);
          $ref(() => 2);
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
        final func = $handle((bool input) {
          return $if(input, () {
            return 1;
          }, orElse: () => 2);
        }, (effect) {});
        expect(func(true), 1);
        expect(func(false), 2);
      });
      test('should create separated cursor context', () {
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
          $scan((_, __) {
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
          return $scan<int>((prev, __) {
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
  });
}

class _MockEffect<T> implements $Effect {
  final $Ref<T> at;

  _MockEffect(this.at);
}
