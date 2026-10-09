import 'dart:io';

/// Small helper for reading example fixtures shared by the tests. `dart test`
/// runs with the package root as its working directory, so example-relative
/// paths resolve directly.
String loadExample(String name) => File('example/$name').readAsStringSync();

/// The demo program from the original `parserRun.js`.
const String demoProgram = 'begin A := BB + 314 + A; end \$';
