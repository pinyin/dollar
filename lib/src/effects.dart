import 'package:dollar/dollar.dart';

class $UpdateVar<T> extends $Effect {
  final T to;
  final $Cursor at;

  @override
  bool operator ==(other) {
    return other is $UpdateVar<T> &&
        other.runtimeType == runtimeType &&
        other.to == to &&
        other.at == at;
  }

  @override
  int get hashCode => to.hashCode;

  $UpdateVar(this.to, this.at);
}

class $AddListener<T> implements $Effect {
  final $Cursor at;
  final Function(T) callback;
  final Type type;

  @override
  bool operator ==(other) {
    return other is $AddListener<T> &&
        other.runtimeType == runtimeType &&
        other.callback == callback;
  }

  @override
  int get hashCode => runtimeType.hashCode ^ callback.hashCode;

  $AddListener(this.callback, this.at) : type = T;
}

class $End {}
