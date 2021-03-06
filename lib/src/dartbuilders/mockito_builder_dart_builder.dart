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

  String createUnimplementedErrorMessage(MockitoConfig mockitoConfig) {
    final mockerName = mockitoConfig.mockerName;
    return '''Error, a mock class for \'\$T\' has not been generated yet.
Navigate to the \'$mockerName\' method and add the type to the types list in the \'$GenerateMocker\' annotation.
Finally run the build command: \'flutter packages pub run build_runner build\'.''';
  }

  Block createSwitchStatement(MockitoConfig mockitoConfig) {
    final list = <Code>[];
    list.add(Code("switch(T) {"));
    mockitoConfig.mockDefs.forEach((mockDef) {
      list.add(Code("case ${mockDef.type}:"));
      list.add(Code("final mock = ${mockDef.targetClassName}();"));
      list.add(Code("if (enableThrowOnMissingStub) {"));
      list.add(Code("throwOnMissingStub(mock);"));
      list.add(Code("}"));
      list.add(Code("return mock;"));
    });
    list.add(Code(
        "default: throw UnimplementedError(\'\'\'${createUnimplementedErrorMessage(mockitoConfig)}\'\'\');"));
    list.add(Code("}"));
    return Block.of(list);
  }

  Method buildMockerMethod(MockitoConfig mockitoConfig) {
    final name = mockitoConfig.mockerName;
    var throwOnMissingStubBuilder = ParameterBuilder();
    throwOnMissingStubBuilder.name = "enableThrowOnMissingStub";
    throwOnMissingStubBuilder.defaultTo = Code("false");
    throwOnMissingStubBuilder.named = true;
    throwOnMissingStubBuilder.type = refer('bool');
    final throwOnMissingStub = throwOnMissingStubBuilder.build();

    return Method((b) => b
      ..name = "_\$$name"
      ..returns = refer('dynamic')
      ..types.add(refer("T"))
      ..optionalParameters.add(throwOnMissingStub)
      ..body = createSwitchStatement(mockitoConfig));
  }
}
