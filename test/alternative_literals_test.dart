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

import 'package:betto_abnf/abnf.dart' show alternativeLiterals;
import 'package:test/test.dart' as t;

void main() {
  t.group('alternative literals', () {
    t.test('single literal', () async {
      final alts = alternativeLiterals(['en']);
      t.expect(alts.parse('en').success, true);
      t.expect(alts.parse('e').success, false);
    });

    t.test('multiple literals', () async {
      final alts = alternativeLiterals(['en', 'de']);
      t.expect(alts.parse('en').success, true);
      t.expect(alts.parse('de').success, true);
      t.expect(alts.parse('e').success, false);
    });

    t.test('jagged set', () async {
      final alts = alternativeLiterals(['au', 'aust', 'aus']);
      final result = alts.parse('aust');
      t.expect(result.success, true);
      t.expect(result.remaining, '');
      t.expect(result.lexeme, 'aust');
    });
  });
}
