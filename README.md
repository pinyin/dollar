# dollar

Write side effects in sync functions.

Inspired by hooks in React.

## Usage

```dart

final func = $handle((bool input) {
  final a = $cursor(() => 1);
  final b = $if(input, () {
    return $cursor(() => 2);
  }, orElse: ()=> $cursor(()=> 3));
  a.value ++; 
  b.value --;
  // use a / b to trigger side effects
}, effects.add);
// values of a & b will be kept across different calls
func(true);
// a.value == 2, b.value == 1
func(true);
// a.value == 3, b.value == 0
func(false);
// a.value == 4, b.value == 2
func(false);
// a.value == 5, b.value == 1

```


