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
  group('CharacterElement', () {
    test('matches specific character', () {
      final charA = abnf.character(0x41); // 'A'
      expect(charA.parse('A').success, isTrue);
      expect(charA.parse('B').success, isFalse);
    });

    test('matches 32-bit unicode points (surrogate pairs)', () {
      final charEmoji = abnf.character(0x1F600); // 😀
      final result = charEmoji.parse('😀test');
      expect(result.success, isTrue);
      expect(result.lexeme, '😀');
      expect(result.remaining, 'test');
    });
  });

  group('OptionalSequence', () {
    test('matches content when present', () {
      final opt = abnf.optional([abnf.literal('A')]);
      final result = opt.parse('AB');
      expect(result.success, isTrue);
      expect(result.remaining, 'B');
      expect(result.lexeme, 'A');
    });

    test('succeeds without consuming when content is absent', () {
      final opt = abnf.optional([abnf.literal('A')]);
      final result = opt.parse('B');
      expect(result.success, isTrue);
      expect(result.remaining, 'B');
      expect(result.lexeme, isEmpty);
    });
  });

  group('Group', () {
    test('groups elements together into one sequence', () {
      final g = abnf.group([abnf.literal('A'), abnf.literal('B')]);
      expect(g.parse('ABC').success, isTrue);
      expect(g.parse('AC').success, isFalse);
    });
  });

  group('ValueRange boundary logic', () {
    test('respects inclusive bounds', () {
      final range = abnf.valueRange(0x30, 0x39); // '0' - '9'
      expect(range.parse('0').success, isTrue); // Lower bound
      expect(range.parse('9').success, isTrue); // Upper bound
      expect(range.parse('/').success, isFalse); // Below
      expect(range.parse(':').success, isFalse); // Above
    });

    test('handles 32-bit unicode points (surrogate pairs)', () {
      // Range covering several emoji faces
      final range = abnf.valueRange(0x1F600, 0x1F605); // 😀 to 😅
      final result = range.parse('😁hello'); // 😁 is 0x1F601
      expect(result.success, isTrue);
      expect(result.lexeme, '😁');
      expect(result.remaining, 'hello');

      expect(range.parse('😎').success, isFalse); // 0x1F60E (Above range)
    });

    test('fails safely on empty input or multi-char', () {
      final range = abnf.valueRange(0x30, 0x39);
      expect(range.parse('').success, isFalse);
      // Dart Character.length works properly here
      expect(range.parse('12').success, isTrue);
      expect(range.parse('12').remaining, '2');
    });
  });

  group('GrammarPrinter', () {
    test('correctly stringifies elements', () {
      final syntax = abnf.grammar(
        'test',
        abnf.rule(
          'entry',
          abnf.alternatives([
            abnf.group([abnf.literal('A'), abnf.literal('B')]),
            abnf.optional([abnf.valueRange(0x30, 0x39)]),
            abnf.variableRepetition(abnf.character(0x20), min: 1, max: 3),
          ]),
        ),
      );
      final printer = abnf.GrammarPrinter(syntax);
      final out = printer.toString();
      expect(out, contains('entry := ("A" "B") / [%x30-39] / 1*3(%x20)'));
    });
  });

  group('ParseTreeWalker post-order traversal', () {
    test('visits children before parents', () {
      final syntax = abnf.grammar(
        'root',
        abnf.rule('child', abnf.literal('A')),
      );
      final result = syntax.parse('A');
      final walker = abnf.ParseTreeWalker(result);
      final visitedRules = <String>[];

      walker.visitPostOrder((node) {
        if (node.ruleName != null) {
          visitedRules.add(node.ruleName!);
        }
        return true;
      });

      expect(visitedRules, ['child', 'root']);
    });
  });

  group('ParseResult utilities', () {
    test('toMap provides complete serialization', () {
      final result = abnf.literal('A').parse('A');
      final map = result.toMap();
      expect(map['success'], isTrue);
      expect(map['lexeme'], 'A');
      expect(map['remaining'], isEmpty);
      expect(map['stack'], isA<List>());
    });

    test('getRuleLexemes protects against cycles', () {
      // Create a recursive grammar result
      final res1 = abnf.ParseResult(true, '', lexeme: 'a', ruleName: 'A');
      final res2 = abnf.ParseResult(true, '', lexeme: 'b', ruleName: 'B');

      // Manually create a cycle
      res1.stack.push(res2);
      res2.stack.push(res1);

      // Should not hang
      final lexemes = res1.getRuleLexemes('A');
      expect(lexemes, contains('a'));
    });
  });

  group('Grammar and Rule edge cases', () {
    test('Rule.toString handles nested rules correctly', () {
      final inner = abnf.rule('inner', abnf.literal('a'));
      final outer = abnf.rule('outer', inner);
      expect(outer.toString(), 'outer = inner');
    });

    test('Grammar.parse failure on unconsumed input', () {
      final g = abnf.grammar('g', abnf.rule('r', abnf.character(0x41)));
      final result = g.parse('AB');
      expect(result.success, isFalse);
      expect(result.remaining, 'B');
    });
  });
}
