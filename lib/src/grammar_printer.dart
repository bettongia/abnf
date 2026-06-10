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

import 'grammar.dart';

class GrammarPrinter extends ElementVisitor<Map<String, String>> {
  final _rules = <Rule>{};
  final Grammar grammar;
  final String Function(Map<String, String>) printerFunction;

  GrammarPrinter(this.grammar, {this.printerFunction = formatOutputText});

  @override
  String toString() => printerFunction(visitElement(grammar));

  /// Prints the results from GrammarPrinter in a readable format.
  ///
  /// The space between the rule names and their definition is set to
  /// a standard width based on the longest rule name.
  static String formatOutputText(Map<String, String> rules) {
    final maxWidth = rules.keys
        .reduce((a, b) => a.length > b.length ? a : b)
        .length;

    return rules.entries
        .map((entry) => '${entry.key.padRight(maxWidth)} := ${entry.value}')
        .toList()
        .join('\n');
  }

  Map<String, String> formatOutputMap() => visitElement(grammar);

  Map<String, String> _extractRules(ElementSequence elements) {
    final r = <String, String>{}; // Start empty

    for (final element in elements) {
      if (element is Rule) {
        r.addAll(visitRule(element));
      } else {
        // Visit the nested element AND merge its results into our map
        r.addAll(visitElement(element));
      }
    }
    return r;
  }

  @override
  Map<String, String> visitAlternativeLiterals(AlternativeLiterals element) =>
      {};

  @override
  Map<String, String> visitAlternatives(Alternatives alternatives) =>
      _extractRules(alternatives.elements);

  @override
  Map<String, String> visitConcatenation(Concatenation concatenation) =>
      _extractRules(concatenation.sequence);

  @override
  Map<String, String> visitGrammar(Grammar grammar) =>
      visitElement(grammar.entryRule);

  @override
  Map<String, String> visitGroup(Group group) => _extractRules(group.elements);

  @override
  Map<String, String> visitLiteralElement(LiteralElement element) => {};

  @override
  Map<String, String> visitOptionalSequence(OptionalSequence sequence) =>
      _extractRules(sequence.elements);

  @override
  Map<String, String> visitRepetition(Repetition repetition) =>
      _extractRules([repetition.element]);

  @override
  Map<String, String> visitRule(Rule rule) {
    if (_rules.contains(rule)) {
      return {};
    }
    _rules.add(rule);
    return {rule.name: rule.element.toString(), ...visitElement(rule.element)};
  }

  @override
  Map<String, String> visitSequence(Sequence sequence) =>
      _extractRules(sequence.elements);

  @override
  Map<String, String> visitValueRange(ValueRange range) => {};

  @override
  Map<String, String> visitCharacterElement(CharacterElement element) => {};

  @override
  Map<String, String> visitEmptyElement(EmptyElement element) => {};

  @override
  Map<String, String> visitNegativeLookahead(NegativeLookahead element) => {};
}
