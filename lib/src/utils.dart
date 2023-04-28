import 'package:dollar/dollar.dart';

/// combine handlers from right to left
/// every lefter handler is provided as the context of the righter handler
$EffectHandlerCreator $combineHandlers(
    Iterable<$EffectHandlerCreator> createHandlers) {
  return createHandlers
      .reduce((l, r) => ($EffectHandler? current) => r(l(current)));
}

extension AndBool on bool {
  bool operator &(bool other) {
    return and(other);
  }

  bool and(bool other) {
    return this && other;
  }
}

extension OrBool on bool {
  bool operator |(bool other) {
    return or(other);
  }

  bool or(bool other) {
    return this || other;
  }
}

extension IterableEquals on Iterable {
  bool shallowEqualsTo(Iterable? other) {
    if (identical(this, other)) return true;
    if (this == null || other == null) return false;
    var it1 = this.iterator;
    var it2 = other.iterator;
    while (true) {
      bool hasNext = it1.moveNext();
      if (hasNext != it2.moveNext()) return false;
      if (!hasNext) return true;
      if (it1.current != it2.current) return false;
    }
  }
}
