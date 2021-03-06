# dollar

[![Build Status](https://travis-ci.com/pinyin/dollar.svg?branch=master)](https://travis-ci.com/pinyin/dollar)

A DSL to keep state in your functions.

Inspired by React hooks.

## Usage

```dart

import 'package:dollar/dollar.dart';

final func = $bind((bool input) {
  final a = $cursor(() => 1).value;
  final b = $if(input, () {
    return $cursor(() => 2);
  }, orElse: ()=> $cursor(()=> 3)).value;
  a.value ++; 
  b.value --;
  // a.value & b.value will be kept across calls
}, (_) {});
func(true);
// a.value == 2, b.value == 1
func(true);
// a.value == 3, b.value == 0
func(false);
// a.value == 4, b.value == 2
func(false);
// a.value == 5, b.value == 1

```

See tests for more examples.

