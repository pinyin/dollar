import 'package:dollar/dollar.dart';

class $UpdateVar<T> extends $Effect {
  final T from;
  final T to;
  final $Ref at;

  @override
  bool operator ==(other) {
    return other is $UpdateVar<T> &&
        other.runtimeType == runtimeType &&
        other.from == from &&
        other.to == to &&
        other.at == at;
  }

  @override
  int get hashCode => from.hashCode ^ to.hashCode;

  $UpdateVar(this.from, this.to, this.at);
}

class $AddListener<T> implements $Effect {
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

  $AddListener(this.callback) : type = T;
}

class $RemoveListener<T> implements $Effect {
  final Function(T) callback;
  final Type type;

  @override
  bool operator ==(other) {
    return other is $RemoveListener<T> &&
        other.runtimeType == runtimeType &&
        other.callback == callback;
  }

  @override
  int get hashCode => runtimeType.hashCode ^ callback.hashCode;

  $RemoveListener(this.callback) : type = T;
}

class $Ended implements $Effect {}
