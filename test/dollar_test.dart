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
          $cursor(() => $effect(effects.length + 1));
          $cursor(() => $effect(effects.length + 1));
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
        $Cursor<int> cursor;
        final func = $handle((_) {
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
        final func = $handle((bool input) {
          return $if(input, () {
            return 1;
          }, orElse: () => 2);
        }, (effect) {});
        expect(func(true), 1);
        expect(func(false), 2);
      });
      test('should create separated cursor context', () {
        $Cursor<int> a;
        $Cursor<int> b;
        final func = $handle((bool input) {
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
}
