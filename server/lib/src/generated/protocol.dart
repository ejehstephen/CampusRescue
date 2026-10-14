import 'package:serverpod/protocol.dart' as serverpod;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod/src/generated/protocol.dart' as serverpod_gen;

class SimpleMessage implements SerializableModel {
  final String message;
  SimpleMessage([this.message = 'ok']);

  @override
  Map<String, dynamic> toJson() => {'message': message};
}

class Protocol extends SerializationManagerServer {
  static final Protocol instance = Protocol();

  final serverpod_gen.Protocol _serverpod = serverpod_gen.Protocol();

  @override
  Map<String, String> get classNameTable => {};

  @override
  Map<String, String> get getAliasTable => {};

  @override
  String getModuleName() => 'campusrescue';

  @override
  Table? getTableForType(Type t) {
    return _serverpod.getTableForType(t);
  }

  @override
  List<serverpod.TableDefinition> getTargetTableDefinitions() =>
      serverpod_gen.Protocol.targetTableDefinitions;

  @override
  T deserialize<T>(dynamic data, [Type? t]) {
    t ??= T;
    try {
      return _serverpod.deserialize<T>(data, t);
    } catch (_) {
      return super.deserialize<T>(data, t);
    }
  }

  @override
  String? getClassNameForObject(Object? data) {
    return _serverpod.getClassNameForObject(data);
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    try {
      return _serverpod.deserializeByClassName(data);
    } catch (_) {
      return super.deserializeByClassName(data);
    }
  }
}
