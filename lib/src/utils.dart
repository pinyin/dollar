import 'package:dollar/dollar.dart';

/// combine handlers from right to left
/// every lefter handler is provided as the parent of the righter handler
$EffectHandlerCreator $combineHandlers(
    Iterable<$EffectHandlerCreator> createHandlers) {
  return createHandlers
      .reduce((l, r) => ($EffectHandler parent) => r(l(parent)));
}
