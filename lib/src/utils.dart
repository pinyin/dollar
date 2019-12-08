import 'package:dollar/dollar.dart';

/// combine handlers from right to left
/// every lefter handler is provided as the context of the righter handler
$EffectHandlerCreator $combineHandlers(
    Iterable<$EffectHandlerCreator> createHandlers) {
  return createHandlers
      .reduce((l, r) => ($EffectHandler current) => r(l(current)));
}
