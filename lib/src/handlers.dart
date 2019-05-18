import 'dart:async';

import 'package:dollar/dollar.dart';

StreamTransformer<T, R> $transformWith<T, R>(R effects(T event)) {
  return StreamTransformer.fromBind((Stream<T> source) {
    final controller = StreamController<R>();

    var hasVarUpdate = false;
    effects = $handle(effects, (effect) {
      if (effect is $UpdateVar) {
        hasVarUpdate = true;
        scheduleMicrotask(() {
          if (!hasVarUpdate) return;
          hasVarUpdate = false;
          controller.add(effects(null));
        });
      }
    });

    StreamSubscription<T> subscription;
    controller.onListen = () {
      subscription = source.listen((event) {
        controller.add(effects(event));
      }, onDone: () {
        controller.close();
      }, onError: (error) {
        controller.addError(error);
      });
    };
    controller.onPause = () {
      subscription.pause();
    };
    controller.onResume = () {
      subscription.resume();
    };
    controller.onCancel = () {
      subscription.cancel();
    };
    return controller.stream.asBroadcastStream();
  });
}
