import 'package:dollar/dollar.dart';
import 'package:test/test.dart';

void main() {
  group('core', () {
    group('handle', () {
      test('should wrap input function in a handler', () {
        final effects = [];
        final func = $handle((_) {
          $effect(1);
          $effect(2);
        }, effects.add);
        expect(effects, []);
        func(null);
        expect(effects, [1, 2]);
      });
      test('should provide a cursor context', () {
        final effects = [];
        final func = $handle((_) {
          $ref(() => $effect(effects.length + 1));
          $ref(() => $effect(effects.length + 1));
        }, effects.add);
        expect(effects, []);
        func(null);
        expect(effects, [1, 2]);
        func(null);
        expect(effects, [1, 2]);
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
        final effects = [];
        final func = $handle((_) {
          return $var(() => 1);
        }, effects.add);
        var v = func(null);
        v.value = 2;
        expect(effects, [$VarUpdateEffect(1, 2)]);
        effects.clear();
        v = func(null);
        v.value = 3;
        expect(effects, [$VarUpdateEffect(2, 3)]);
      });
    });

    group('scan', () {
      test('should run work when keys are not equal', () {
        int runCount = 0;
        int cleanCount = 0;
        $Ref keyRef;
        final func = $handle((_) {
          keyRef = $ref(() => 0);
          $scan((_, __) {
            runCount++;
            return () {
              cleanCount++;
            };
          }, [keyRef.value]);
        }, (_) {});
        func(null);
        expect(runCount, 1);
        expect(cleanCount, 0);
        func(null);
        expect(runCount, 1);
        expect(cleanCount, 0);
        keyRef.value++;
        func(null);
        expect(runCount, 2);
        expect(cleanCount, 1);
        func(null);
        expect(runCount, 2);
        expect(cleanCount, 1);
      });
    });
  });
}
