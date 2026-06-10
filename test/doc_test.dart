// Copyright 2026 The Authors. See the AUTHORS file for details.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:betto_abnf/abnf.dart';
import 'package:test/test.dart';

/// Tests that mirror the README example code so the documented API
/// stays correct and doesn't regress silently.
void main() {
  test('README basic example', () {
    final g = grammar(
      'iso-639-1-language',
      rule('language', repetition(alphaLower, 2)),
    );

    expect(g.parse('en').success, isTrue);
    expect(g.parse('EN').success, isFalse);
    expect(g.parse('en-US').success, isFalse);

    final result = g.parse('en');
    expect(result.getRuleLexemes('language'), ['en']);

    // Walker should be constructable and printable without error.
    final walker = ParseTreeWalker(result);
    expect(walker.toString(), isNotEmpty);
  });
}
