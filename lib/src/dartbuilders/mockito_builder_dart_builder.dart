import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mockito_builder/src/models/models.dart';
import 'package:mockito_builder_annotations/mockito_builder_annotations.dart';

class MockitoDartBuilder {
  String buildDartFile(MockitoConfig mockitoConfig) {
    final lib = Library((b) => b
      ..body.addAll(mockitoConfig.mockDefs.map(buildMockitoClass).toList())
      ..body.add(buildMockerMethod(mockitoConfig)));
    final emitter = DartEmitter();
    return DartFormatter().format('${lib.accept(emitter)}');
  }

  Class buildMockitoClass(MockDef mockitoDef) {
    return Class((b) => b
      ..name = mockitoDef.targetClassName
      ..extend = refer("Mock")
      ..implements.add(refer(mockitoDef.type)));
  }

  String createUnimplementedErrorMessage() {
    return '\'Error, you forgot to specify \"\$T\" in the $GenerateMocker annotation\'';
  }

  Block createSwitchStatement(MockitoConfig mockitoConfig) {
    final list = <Code>[];
    list.add(Code("switch(T) {"));
    mockitoConfig.mockDefs.forEach((mockDef) {
      list.add(Code("case ${mockDef.type}:"));
      list.add(Code("return ${mockDef.targetClassName}();"));
    });
    list.add(Code(
        "default: throw UnimplementedError(${createUnimplementedErrorMessage()});"));
    list.add(Code("}"));
    return Block.of(list);
  }

  Method buildMockerMethod(MockitoConfig mockitoConfig) {
    final name = mockitoConfig.mockerName;
    return Method((b) => b
      ..name = "_\$$name"
      ..returns = refer('dynamic')
      ..types.add(refer("T"))
      ..body = createSwitchStatement(mockitoConfig));
  }
}