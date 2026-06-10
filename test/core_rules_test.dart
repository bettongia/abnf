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

import 'package:betto_abnf/betto_abnf.dart' as abnf;
import 'package:test/test.dart';

void main() {
  group('Core Rules', () {
    test('ALPHA-LOWER', () {
      final syntax = abnf.grammar('test', abnf.alphaLower);
      expect(syntax.parse('a').success, true);
      expect(syntax.parse('z').success, true);
      expect(syntax.parse('m').success, true);
      expect(syntax.parse('A').success, false);
      expect(syntax.parse('0').success, false);
    });

    test('ALPHA-UPPER', () {
      final syntax = abnf.grammar('test', abnf.alphaUpper);
      expect(syntax.parse('A').success, true);
      expect(syntax.parse('Z').success, true);
      expect(syntax.parse('M').success, true);
      expect(syntax.parse('a').success, false);
      expect(syntax.parse('0').success, false);
    });

    test('ALPHA', () {
      final syntax = abnf.grammar('test', abnf.alpha);
      expect(syntax.parse('a').success, true);
      expect(syntax.parse('z').success, true);
      expect(syntax.parse('A').success, true);
      expect(syntax.parse('Z').success, true);
      expect(syntax.parse('1').success, false);
      expect(syntax.parse('_').success, false);
    });

    test('BIT', () {
      final syntax = abnf.grammar('test', abnf.bit);
      expect(syntax.parse('0').success, true);
      expect(syntax.parse('1').success, true);
      expect(syntax.parse('2').success, false);
      expect(syntax.parse('a').success, false);
    });

    test('CHAR', () {
      final syntax = abnf.grammar('test', abnf.char);
      expect(syntax.parse('\x01').success, true);
      expect(syntax.parse('\x7F').success, true);
      expect(syntax.parse('\xFF').success, true);
      // \x00 is not in range 0x01-FF
      expect(syntax.parse('\x00').success, false);
    });

    test('CR', () {
      final syntax = abnf.grammar('test', abnf.cr);
      expect(syntax.parse('\r').success, true);
      expect(syntax.parse('\n').success, false);
    });

    test('CRLF', () {
      final syntax = abnf.grammar('test', abnf.crlf);
      expect(syntax.parse('\r\n').success, true);
      expect(syntax.parse('\n').success, false);
      expect(syntax.parse('\r').success, false);
    });

    test('CTL', () {
      final syntax = abnf.grammar('test', abnf.ctl);
      expect(syntax.parse('\x00').success, true);
      expect(syntax.parse('\x1F').success, true);
      expect(syntax.parse('\x7F').success, true);
      expect(syntax.parse(' ').success, false); // %x20
    });

    test('DIGIT', () {
      final syntax = abnf.grammar('test', abnf.digit);
      expect(syntax.parse('0').success, true);
      expect(syntax.parse('9').success, true);
      expect(syntax.parse('a').success, false);
    });

    test('ALPHANUM', () {
      final syntax = abnf.grammar('test', abnf.alphanum);
      expect(syntax.parse('a').success, true);
      expect(syntax.parse('Z').success, true);
      expect(syntax.parse('0').success, true);
      expect(syntax.parse('9').success, true);
      expect(syntax.parse('-').success, false);
    });

    test('DQUOTE', () {
      final syntax = abnf.grammar('test', abnf.dquote);
      expect(syntax.parse('"').success, true);
      expect(syntax.parse("'").success, false);
    });

    test('HEX-LETTERS', () {
      final syntax = abnf.grammar('test', abnf.hexletters);
      expect(syntax.parse('a').success, true);
      expect(syntax.parse('f').success, true);
      expect(syntax.parse('A').success, true); // Case-insensitive
      expect(syntax.parse('F').success, true);
      expect(syntax.parse('g').success, false);
    });

    test('HEXDIG', () {
      final syntax = abnf.grammar('test', abnf.hexdig);
      expect(syntax.parse('0').success, true);
      expect(syntax.parse('9').success, true);
      expect(syntax.parse('a').success, true);
      expect(syntax.parse('f').success, true);
      expect(syntax.parse('A').success, true);
      expect(syntax.parse('F').success, true);
      expect(syntax.parse('g').success, false);
    });

    test('HTAB', () {
      final syntax = abnf.grammar('test', abnf.htab);
      expect(syntax.parse('\t').success, true);
      expect(syntax.parse(' ').success, false);
    });

    test('LF', () {
      final syntax = abnf.grammar('test', abnf.lf);
      expect(syntax.parse('\n').success, true);
      expect(syntax.parse('\r').success, false);
    });

    test('SP', () {
      final syntax = abnf.grammar('test', abnf.sp);
      expect(syntax.parse(' ').success, true);
      expect(syntax.parse('\t').success, false);
    });

    test('VCHAR', () {
      final syntax = abnf.grammar('test', abnf.vchar);
      expect(syntax.parse('!').success, true); // %x21
      expect(syntax.parse('~').success, true); // %x7E
      expect(syntax.parse(' ').success, false); // %x20
      expect(syntax.parse('\x7F').success, false);
    });

    test('WSP', () {
      final syntax = abnf.grammar('test', abnf.wsp);
      expect(syntax.parse(' ').success, true);
      expect(syntax.parse('\t').success, true);
      expect(syntax.parse('\n').success, false);
    });

    test('Optional-WSP', () {
      final syntax = abnf.optionalWsp;
      expect(syntax.parse('').success, true);
      expect(syntax.parse(' ').success, true);
      expect(syntax.parse('\t').success, true);
      expect(syntax.parse('  \t ').success, true);
      expect(syntax.parse('a').success, true); // Matches empty, 'a' remains
      expect(syntax.parse('a').remaining, 'a');
    });
  });
}
