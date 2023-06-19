# dollar

[![Build Status](https://travis-ci.com/pinyin/dollar.svg?branch=master)](https://travis-ci.com/pinyin/dollar)

A DSL to keep state in your functions.

Inspired by React hooks.

## Usage

```dart

final func = $1((bool input) {
  final a = $value(() => 1);
  $fork(input);
  final b = input ? $value(() => 2) : $value(() => 3);
  $merge();
  a.value++;
  b.value--;
  return [a.value, b.value];
});
expect
(
func(true), [2, 1]);
expect(func(true), [3, 0]);
expect(func(false), [4, 2]);
expect(func(false), [5, 1]);
expect(func(true), [6, -1]);
expect(func(false), [7, 0]);
```

See tests for more usages.

