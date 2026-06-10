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
  group('basic literal checks', () {
    test('single literal string', () async {
      final language = abnf.rule('language', abnf.literal('en'));

      final languageTag = abnf.grammar('Language-Tag', language);

      expect(languageTag.parse('en').success, true);
      // RFC 5234 §2.3: string literals are case-insensitive by default
      expect(languageTag.parse('EN').success, true);
      expect(languageTag.parse('En').success, true);
      expect(languageTag.parse('e').success, false);
      expect(languageTag.parse('n').success, false);
      expect(languageTag.parse('de').success, false);
    });

    test('case-sensitive literal', () async {
      final language = abnf.rule('language', abnf.caseSensitiveLiteral('en'));

      final languageTag = abnf.grammar('Language-Tag', language);

      expect(languageTag.parse('en').success, true);
      expect(languageTag.parse('EN').success, false);
      expect(languageTag.parse('En').success, false);
    });

    test('single literal string - error', () async {
      final language = abnf.rule('language', abnf.literal('en'));

      final languageTag = abnf.grammar('Language-Tag', language);

      final result = languageTag.parse('eng');

      expect(result.success, false);
      expect(result.remaining, 'g');

      expect(result.getRuleLexemes(language.name), ['en']);
    });

    test('alternative literal strings', () async {
      final language = abnf.rule(
        'language',
        abnf.alternatives([abnf.literal('en'), abnf.literal('de')]),
      );

      final languageTag = abnf.grammar('Language-Tag', language);

      final result = languageTag.parse('en');
      expect(result.success, true);
      expect(result.getRuleLexemes(language.name), ['en']);

      expect(languageTag.parse('de').success, true);
      expect(languageTag.parse('fr').success, false);
    });

    test('concatenated literal strings', () async {
      final langtag = abnf.rule(
        'langtag',
        abnf.concatenation([
          abnf.literal('en'),
          abnf.literal('-'),
          abnf.literal('AU'),
        ]),
      );

      final languageTag = abnf.grammar('Language-Tag', langtag);

      final result = languageTag.parse('en-AU');
      expect(result.success, true);

      expect(languageTag.parse('en').success, false);
    });

    test('concatenated Namedrules with literal strings', () async {
      final language = abnf.rule('language', abnf.literal('en'));
      final region = abnf.rule('region', abnf.literal('AU'));

      final langtag = abnf.rule(
        'langtag',
        abnf.concatenation([language, abnf.literal('-'), region]),
      );

      final languageTag = abnf.grammar('Language-Tag', langtag);

      final result = languageTag.parse('en-AU');
      expect(result.success, true);

      expect(result.getRuleLexemes(language.name), ['en']);

      expect(result.getRuleLexemes(region.name), ['AU']);

      expect(result.success, true);
      expect(languageTag.parse('en').success, false);
    });
  });

  group('core NamedRules', () {
    test('alpha', () async {
      final syntax = abnf.grammar('test', abnf.alpha);
      expect(syntax.parse('x').success, true);
      expect(syntax.parse('X').success, true);
      expect(syntax.parse('1').success, false);
    });

    test('digit', () async {
      final syntax = abnf.grammar('test', abnf.digit);
      expect(syntax.parse('0').success, true);
      expect(syntax.parse('9').success, true);
      expect(syntax.parse('10').success, false);
      expect(syntax.parse('a').success, false);
    });

    for (final entry in [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      'a',
      'b',
      'c',
      'd',
      'e',
      'f',
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
    ]) {
      test('hexdig: $entry', () async {
        final syntax = abnf.grammar('test', abnf.hexdig);
        expect(syntax.parse(entry).success, true);
      });
    }
  });

  group('repetitions', () {
    test('specific repetitions', () {
      final syntax = abnf.grammar(
        'langtag',
        abnf.rule('language', abnf.repetition(abnf.alpha, 4)),
      );

      expect(syntax.parse('aaaa').success, true);
      expect(syntax.parse('aaa').success, false);
    });

    test('variable repetitions', () {
      final syntax = abnf.grammar(
        'langtag',
        abnf.rule(
          'language',
          abnf.variableRepetition(abnf.alpha, min: 2, max: 3),
        ),
      );

      expect(syntax.parse('en').success, true);
      expect(syntax.parse('eng').success, true);
      expect(syntax.parse('english').success, false);
    });

    test('infinite max repetitions', () {
      final syntax = abnf.grammar(
        'test',
        abnf.rule(
          'alphabet',
          abnf.concatenation([
            abnf.rule(
              'x-list',
              abnf.variableRepetition(
                abnf.rule('x', abnf.literal('x')),
                min: 1,
              ),
            ),
            abnf.rule(
              'y-list',
              abnf.variableRepetition(abnf.rule('y', abnf.literal('y'))),
            ),
          ]),
        ),
      );

      expect(syntax.parse('x').success, true);
      //print(jsonEncode(syntax.parse('xy').toMap()));
      expect(syntax.parse('xy').success, true);
      expect(syntax.parse('xxx').success, true);
      expect(syntax.parse('xxxxxxxxxxx').success, true);
      expect(syntax.parse('xxxxxxxxxxxyyyyyy').success, true);
      expect(syntax.parse('xxxxxxxxxxxyyyyyyz').success, false);
    });

    test('mixed repetitions', () {
      final syntax = abnf.grammar(
        'Language-Tag',
        abnf.rule(
          'langtag',
          abnf.rule(
            'language',
            abnf.alternatives([
              abnf.variableRepetition(abnf.alpha, min: 2, max: 3),
              abnf.repetition(abnf.alpha, 4),
              abnf.variableRepetition(abnf.alpha, min: 5, max: 8),
            ]),
          ),
        ),
      );

      expect(syntax.parse('en').success, true);
      expect(syntax.parse('eng').success, true);
    });
  });

  group('Repetition failure', () {
    test('returns original source as remaining on failure', () {
      // §1e: on a failed repetition, remaining should be the original source,
      // not the remaining from the last sub-element attempt.
      final syntax = abnf.grammar(
        'test',
        abnf.rule('letters', abnf.variableRepetition(abnf.alpha, min: 3)),
      );
      final result = syntax.parse('ab'); // only 2, need at least 3
      expect(result.success, false);
      expect(result.remaining, 'ab'); // original source, not ''
    });
  });

  group('abnfRuleName', () {
    final ruleNameGrammar = abnf.grammar('rulename', abnf.Rule.abnfRuleName);

    test('single alpha is valid', () {
      expect(ruleNameGrammar.parse('a').success, true);
    });

    test('multi-character name is valid', () {
      expect(ruleNameGrammar.parse('rulename').success, true);
      expect(ruleNameGrammar.parse('rule-name').success, true);
      expect(ruleNameGrammar.parse('rule1').success, true);
    });

    test('must start with alpha', () {
      expect(ruleNameGrammar.parse('1rule').success, false);
      expect(ruleNameGrammar.parse('-rule').success, false);
    });
  });
}
