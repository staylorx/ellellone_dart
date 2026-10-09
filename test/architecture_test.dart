import 'dart:io';

import 'package:dart_arch_test/dart_arch_test.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

/// The architecture boundary gate: enforces the bibliography's clean-architecture
/// shape on this single-package repo (bible §2.9). The onion layers are the
/// clean-architecture rings under `lib/src/`: `domain` innermost, then
/// `contracts`, `usecases`, and `adapters` outermost — dependencies point only
/// inward.
void main() {
  late DependencyGraph graph;

  setUpAll(() async {
    graph = await Collector.buildGraph(Directory.current.path);
  });

  group('Architecture', () {
    test('scans a non-trivial set of package libraries', () {
      final libs = Collector.allLibraries(
        graph,
      ).where((u) => u.startsWith('package:ellellone/')).toList();
      (libs.length > 3).should.be(true);
    });

    test('frees the library sources from import cycles', () {
      shouldBeFreeOfCycles(filesMatching('src/**'), graph);
    });

    test('keeps src from importing the public barrel (front door)', () {
      shouldNotDependOn(
        filesMatching('src/**'),
        filesMatching('ellellone.dart'),
        graph,
      );
    });

    test('points dependencies inward (onion)', () {
      defineOnion({
        'domain': 'src/domain/**',
        'contracts': 'src/contracts/**',
        'usecases': 'src/usecases/**',
        'adapters': 'src/adapters/**',
      }).enforceOnionRules(graph);
    });
  });
}
