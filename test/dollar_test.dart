import 'package:dollar/dollar.dart';
import 'package:test/test.dart';

void main() {
  group('core', () {
    group('handle', () {
      test('should forward effects to handler', () {
        final effects = <_MockEffect>[];
        final func = $handle((_) {
          $effect((cursor) => _MockEffect(1, cursor));
          $effect((cursor) => _MockEffect(2, cursor));
        }, effects.add);
        expect(effects, []);
        func(null);
        expect(effects.map((e) => e.value), [1, 2]);
      });
      test('should create new ref context', () {
        final effects = <_MockEffect>[];
        final func = $handle((_) {
          $effect((cursor) => _MockEffect(1, cursor));
          $effect((cursor) => _MockEffect(2, cursor));
          $handle((_) {
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
    group('ref', () {
      test('should keep updates across calls', () {
        $Cursor<int> ref;
        final func = $handle((_) {
          ref = $cursor(() => 1);
          $cursor(() => 2);
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

  group('expressions', () {
    group('var', () {
      test('should emit VarEffect', () {
        final effects = <$UpdateVar>[];
        final func = $handle((_) {
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

    group('previous', () {
      test('should provide previous value', () {
        final listeners = $Listeners();
        final func = $handle((value) {
          return $previous(value);
        }, $listenAt(listeners));
        expect(func(1), null);
        listeners.trigger($Pass());
        expect(func(2), 1);
        listeners.trigger($Pass());
        expect(func(3), 2);
      });
    });

    group('identical', () {
      test('should compare value and previous value', () {
        final listeners = $Listeners();
        final func = $handle((value) {
          return $identical(value);
        }, $listenAt(listeners));
        expect(func(1), false);
        listeners.trigger($Pass());
        expect(func(2), false);
        listeners.trigger($Pass());
        expect(func(2), true);
        listeners.trigger($Pass());
        expect(func(1), false);
      });
    });

    group('equals', () {
      test('should compare value and previous value', () {
        final listeners = $Listeners();
        final func = $handle((value) {
          return $equals(value);
        }, $listenAt(listeners));
        expect(func(1), false);
        listeners.trigger($Pass());
        expect(func(2), false);
        listeners.trigger($Pass());
        expect(func(2), true);
        listeners.trigger($Pass());
        expect(func(1), false);
      });
    });

    group('shallowEquals', () {
      test('should compare value and previous value', () {
        final listeners = $Listeners();
        final func = $handle((value) {
          return $shallowEquals(value);
        }, $listenAt(listeners));
        expect(func([1]), false);
        listeners.trigger($Pass());
        expect(func([2]), false);
        listeners.trigger($Pass());
        expect(func([2, 2]), false);
        listeners.trigger($Pass());
        expect(func([2, 2]), true);
        listeners.trigger($Pass());
        expect(func([1]), false);
      });
    });

    group('listen', () {
      test('should emit listener event', () {
        final effects = <$Effect>[];
        final listener = (int i) {
          return;
        };
        final func = $handle((_) {
          $listen(listener);
        }, effects.add);
        func(null);
        func(null);
        expect(effects.length, 1);
        expect(effects[0] is $AddListener<int>, true);
      });
      test('should wrap callback into an effect', () {
        final effects = [];
        var result = 0;
        final listener = (int i) {
          final callCount = $cursor(() => 0);
          return callCount.value += i;
        };
        final func = $handle((_) {
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
        final listener = ($Var<int> value) {
          value.value ??= 0;
          value.value++;
          return () {
            closeCount++;
          };
        };
        var result = 0;
        final func = $handle((input) {
          $if(!$identical(input), () {
            result = $fork(listener);
          });
        }, $combineHandlers([$listenAt(listeners), effects.add]));
        func(0);
        expect(result, 1);
        expect(closeCount, 0);
        listeners.trigger($Pass());
        func(1);
        expect(result, 2);
        expect(closeCount, 1);
        listeners.trigger($Pass());
        func(1);
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
}

class _MockEffect<T> implements $Effect {
  final $Cursor<T> at;
  final T value;

  _MockEffect(this.value, this.at);
}
