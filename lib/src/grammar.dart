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

import 'package:betto_common/collections.dart' show Stack;
import 'package:characters/characters.dart';

import 'core_rules.dart';
import 'parse.dart';

/// Visitor interface for traversing ABNF grammar [Element] nodes.
abstract class ElementVisitor<R> {
  R visitAlternativeLiterals(AlternativeLiterals element);
  R visitAlternatives(Alternatives element);
  R visitConcatenation(Concatenation element);
  R visitGroup(Group element);
  R visitLiteralElement(LiteralElement element);
  R visitOptionalSequence(OptionalSequence element);
  R visitRepetition(Repetition element);
  R visitSequence(Sequence element);
  R visitRule(Rule element);
  R visitGrammar(Grammar element);
  R visitValueRange(ValueRange element);
  R visitCharacterElement(CharacterElement element);
  R visitEmptyElement(EmptyElement element);
  R visitNegativeLookahead(NegativeLookahead element);

  R visitElement(Element element) => switch (element) {
    AlternativeLiterals _ => visitAlternativeLiterals(element),
    Alternatives _ => visitAlternatives(element),
    Concatenation _ => visitConcatenation(element),
    Group _ => visitGroup(element),
    LiteralElement _ => visitLiteralElement(element),
    CharacterElement _ => visitCharacterElement(element),
    OptionalSequence _ => visitOptionalSequence(element),
    Repetition _ => visitRepetition(element),
    Sequence _ => visitSequence(element),
    ValueRange _ => visitValueRange(element),
    Grammar _ => visitGrammar(element),
    Rule _ => visitRule(element),
    EmptyElement _ => visitEmptyElement(element),
    NegativeLookahead _ => visitNegativeLookahead(element),
  };
}

/// The base representation of an ABNF grammar element.
sealed class Element {
  /// Attempts to parse the [source] string matching this element.
  ///
  /// Returns a [ParseResult] containing the parsed lexeme and remaining string
  /// on success. On failure, returns a failed [ParseResult].
  ParseResult parse(String source);

  /// Accepts an [ElementVisitor] for traversing the grammar tree.
  void accept(ElementVisitor visitor);

  /// An optional human-readable description of this element.
  String? get description;
}

/// Represents a complete ABNF grammar starting from an entry rule.
final class Grammar implements Element {
  /// The unique name of this grammar.
  final String name;

  @override
  final String? description;

  /// The entry point [Rule] for parsing.
  final Rule entryRule;

  @Deprecated('Use grammar() factory instead.')
  Grammar(this.name, this.entryRule, {this.description});

  Rule get element => entryRule;

  @override
  String toString() => '$name = ${entryRule.name}';

  /// Alias for [entryRule].
  Rule get value => entryRule;

  @override
  ParseResult parse(String source) {
    final result = entryRule.parse(source);
    if (result.remaining.isNotEmpty) {
      // The full source was not consumed so the parsing has failed
      return ParseResult(
        false,
        result.remaining,
        lexeme: result.lexeme,
        ruleName: name,
        element: toString(),
        stack: Stack<ParseResult>()..push(result),
      );
    }
    return ParseResult(
      result.success,
      result.remaining,
      lexeme: result.lexeme,
      ruleName: name,
      element: toString(),
      stack: Stack<ParseResult>()..push(result),
    );
  }

  @override
  void accept(ElementVisitor visitor) => visitor.visitGrammar(this);
}

Grammar grammar(String name, Rule entryRule, {String? description}) =>
    // ignore: deprecated_member_use_from_same_package
    Grammar(name, entryRule, description: description);

/// A named grammar rule combining a name and an underlying [Element].
final class Rule implements Element {
  final String name;
  final Element element;
  @override
  final String? description;

  @Deprecated('Use rule() factory instead.')
  Rule(this.name, this.element, {this.description});

  @override
  String toString() =>
      '$name = ${element is Rule ? (element as Rule).name : element}';

  @override
  ParseResult parse(String source) {
    final result = element.parse(source);

    if (!result.success) {
      return ParseResult(
        false,
        source,
        ruleName: name,
        element: toString(),
        stack: Stack<ParseResult>()..push(result),
      );
    }

    final lexeme = source.substring(0, source.length - result.remaining.length);

    return ParseResult(
      result.success,
      result.remaining,
      lexeme: lexeme,
      ruleName: name,
      element: toString(),
      stack: Stack<ParseResult>()..push(result),
    );
  }

  static final abnfRuleName = rule(
    'rule',
    Concatenation([
      alpha,
      variableRepetition(alternatives([alpha, digit, literal('-')])),
    ]),
  );

  @override
  void accept(ElementVisitor visitor) => visitor.visitRule(this);
}

/// Creates a named [Rule] from a given grammar [element].
Rule rule(String name, Element element, {String? description}) =>
    // ignore: deprecated_member_use_from_same_package
    Rule(name, element, description: description);

/// Represents a single character (code point) element.
final class CharacterElement implements Element {
  /// The 32-bit Unicode code point value.
  final int value;
  @override
  final String? description;

  CharacterElement(this.value, {this.description});

  @override
  void accept(ElementVisitor visitor) => visitor.visitCharacterElement(this);

  @override
  ParseResult parse(String source) {
    if (source.isEmpty) {
      return ParseResult(false, source, element: toString());
    }

    final rune = source.runes.first;
    if (rune == value) {
      // Consume exactly one rune. String.fromCharCodes reconstructs the
      // string correctly even if the rune required a surrogate pair.
      final lexeme = String.fromCharCode(rune);
      return ParseResult(
        true,
        source.substring(lexeme.length),
        lexeme: lexeme,
        element: toString(),
      );
    }
    return ParseResult(false, source, element: toString());
  }

  @override
  String toString() =>
      '%x${value.toRadixString(16).padLeft(2, '0').toUpperCase()}';
}

CharacterElement character(int value, {String? description}) =>
    CharacterElement(value, description: description);

/// Represents a literal string (e.g., `"en"`).
///
/// Per RFC 5234 §2.3, string literals in ABNF are case-**insensitive**
/// by default. Set to `true` to opt into case-sensitive matching
/// (equivalent to the `%s` prefix in RFC 7405).
final class LiteralElement implements Element {
  final String value;

  /// Whether matching is case-sensitive.
  ///
  /// Per RFC 5234 §2.3, string literals in ABNF are case-**insensitive**
  /// by default. Set to `true` to opt into case-sensitive matching
  /// (equivalent to the `%s` prefix in RFC 7405).
  final bool caseSensitive;

  @override
  final String? description;

  LiteralElement(this.value, {this.caseSensitive = false, this.description});

  @override
  // RFC 7405: prefix %s for case-sensitive, %i (or no prefix) for insensitive.
  String toString() => caseSensitive ? '%s"$value"' : '"$value"';

  @override
  ParseResult parse(String source) {
    final matched = caseSensitive
        ? source.startsWith(value)
        : source.toLowerCase().startsWith(value.toLowerCase());
    if (matched) {
      return ParseResult(
        true,
        source.substring(value.length),
        lexeme: source.substring(0, value.length),
        element: toString(),
      );
    }
    return ParseResult(false, source, element: toString());
  }

  @override
  void accept(ElementVisitor visitor) => visitor.visitLiteralElement(this);
}

/// Creates a case-insensitive literal element (the RFC 5234 default).
Element literal(String value, {String? description}) =>
    LiteralElement(value, description: description);

/// Creates a case-sensitive literal element (equivalent to RFC 7405 `%s`).
Element caseSensitiveLiteral(String value, {String? description}) =>
    LiteralElement(value, caseSensitive: true, description: description);

/// Represents a list of alternative literal strings (e.g., `"en" / "de"`).
final class AlternativeLiterals implements Element {
  /// The original (unmodified) values, used for display and for
  /// case-sensitive matching.
  final Set<String> values;

  /// Whether matching is case-sensitive.
  ///
  /// Per RFC 5234 §2.3, string literals in ABNF are case-**insensitive**
  /// by default. Set to `true` to opt into case-sensitive matching
  /// (equivalent to the `%s` prefix in RFC 7405).
  final bool caseSensitive;

  final bool jagged;
  final int minLength;
  @override
  final String? description;

  // Sort the strings by length - longest first.
  // This helps us be greedy when the literal list is jagged.
  static Set<String> _sortBySize(Iterable<String> literals) {
    final l = literals.toList(growable: false);
    l.sort((a, b) => b.length.compareTo(a.length));
    return Set<String>.of(l);
  }

  static bool _isJagged(Iterable<String> literals) => literals.any(
    (element) => element.characters.length != literals.first.characters.length,
  );

  static int _minLength(Iterable<String> literals) => literals.fold<int>(
    literals.first.characters.length,
    (min, e) => min < e.characters.length ? min : e.characters.length,
  );

  AlternativeLiterals(
    Iterable<String> literals, {
    this.caseSensitive = false,
    this.description,
  }) : values = _sortBySize(literals),
       jagged = _isJagged(literals),
       minLength = _minLength(literals);

  @override
  // RFC 7405: emit %s prefix for case-sensitive; bare quotes = case-insensitive.
  String toString() =>
      description ??
      values.map((e) => caseSensitive ? '%s"$e"' : '"$e"').join(' / ');

  ParseResult _parseJaggedSet(String source) {
    final sourceCmp = caseSensitive ? source : source.toLowerCase();
    for (final str in values) {
      final strCmp = caseSensitive ? str : str.toLowerCase();
      if (sourceCmp.startsWith(strCmp)) {
        // Return the slice from the original source to preserve input casing.
        return ParseResult(
          true,
          source.substring(str.length),
          lexeme: source.substring(0, str.length),
          element: toString(),
        );
      }
    }
    return ParseResult(false, source, element: toString());
  }

  ParseResult _parseUniformSet(String source) {
    if (source.characters.length < minLength) {
      return ParseResult(false, source, element: toString());
    }
    final slice = source.characters.take(minLength).toString();
    final sliceCmp = caseSensitive ? slice : slice.toLowerCase();
    // Build a normalised lookup set on demand (not stored, avoids extra field).
    final match = values.any(
      (v) => (caseSensitive ? v : v.toLowerCase()) == sliceCmp,
    );
    if (match) {
      return ParseResult(
        true,
        source.substring(slice.length),
        lexeme: slice,
        element: toString(),
      );
    }
    return ParseResult(false, source, element: toString());
  }

  @override
  ParseResult parse(String source) =>
      jagged ? _parseJaggedSet(source) : _parseUniformSet(source);

  @override
  void accept(ElementVisitor visitor) => visitor.visitAlternativeLiterals(this);
}

/// Creates a case-insensitive set of alternative literals (the RFC 5234 default).
AlternativeLiterals alternativeLiterals(
  Iterable<String> value, {
  String? description,
}) => AlternativeLiterals(value, description: description);

/// Creates a case-sensitive set of alternative literals (equivalent to RFC 7405 `%s`).
AlternativeLiterals caseSensitiveAlternativeLiterals(
  Iterable<String> value, {
  String? description,
}) => AlternativeLiterals(value, caseSensitive: true, description: description);

typedef ElementSequence = Iterable<Element>;

/// A sequence of grammar elements that must be matched in order.
final class Sequence implements Element {
  final ElementSequence elements;
  @override
  final String? description;

  Sequence(this.elements, {this.description});

  @override
  String toString() =>
      description ??
      elements.map((e) => e is Rule ? e.name : e.toString()).join(' ');

  @override
  ParseResult parse(String source) {
    final results = Stack<ParseResult>();
    var remaining = source;

    for (final element in elements) {
      final result = element.parse(remaining);
      results.push(result);

      if (!result.success) {
        // Backtrack: One part of the sequence failed, so the whole sequence fails.
        // We return the source as 'remaining' to allow the caller to retry other
        // paths if this sequence was part of an Alternatives.
        return ParseResult(
          false,
          remaining, // Original remaining before failure
          lexeme: source.substring(0, source.length - remaining.length),
          element: toString(),
          stack: results,
        );
      }
      remaining = result.remaining;
    }
    return ParseResult(
      true,
      remaining,
      lexeme: source.substring(0, source.length - remaining.length),
      element: toString(),
      stack: results,
    );
  }

  @override
  void accept(ElementVisitor visitor) => visitor.visitSequence(this);
}

/// Represents a concatenation of elements that must be matched in order (e.g., `foo bar`).
final class Concatenation implements Element {
  final ElementSequence sequence;
  @override
  final String? description;

  Concatenation(this.sequence, {this.description});

  @override
  String toString() =>
      sequence.map((e) => e is Rule ? e.name : e.toString()).join(' ');

  @override
  ParseResult parse(String source) {
    // Delegate to the shared sequence parsing logic
    return sequence._parseSequenceWithBacktracking(source, toString());
  }

  @override
  void accept(ElementVisitor visitor) => visitor.visitConcatenation(this);
}

Concatenation concatenation(ElementSequence elements) =>
    Concatenation(elements);

/// Represents a group of elements that must be matched together (e.g., `(foo bar)`).
final class Group implements Element {
  final Sequence sequence;
  @override
  final String? description;

  Group(ElementSequence elements, {this.description})
    : sequence = Sequence(elements);

  ElementSequence get elements => sequence.elements;

  @override
  String toString() => '($sequence)';

  @override
  ParseResult parse(String source) => sequence.parse(source);

  @override
  void accept(ElementVisitor visitor) => visitor.visitGroup(this);
}

Group group(ElementSequence elements) => Group(elements);

/// Represents an optional sequence of elements (e.g., `[foo bar]`).
final class OptionalSequence implements Element {
  final Sequence sequence;
  @override
  final String? description;

  OptionalSequence(ElementSequence elements, {this.description})
    : sequence = Sequence(elements);

  ElementSequence get elements => sequence.elements;

  @override
  String toString() => '[$sequence]';

  @override
  ParseResult parse(String source) {
    final result = sequence.elements._parseSequenceWithBacktracking(
      source,
      toString(),
    );

    if (result.success) {
      return result;
    } else {
      // If the sequence parse failed, the optional sequence still succeeds,
      // but consumes nothing and returns an empty result.
      return ParseResult(
        true, // Success is true because it's optional
        source, // No input consumed, remaining is the original source
        element: toString(),
        lexeme: '', // No lexeme produced
        stack: Stack<ParseResult>(), // Empty stack
      );
    }
  }

  /// Returns the alternatives for backtracking: the sequence and an empty match.
  Iterable<Element> get asAlternatives => [sequence, EmptyElement(toString())];

  @override
  void accept(ElementVisitor visitor) => visitor.visitOptionalSequence(this);
}

class EmptyElement implements Element {
  @override
  final String? description;
  EmptyElement(this.description);
  @override
  ParseResult parse(String source) => ParseResult(
    true,
    source,
    element: toString(),
    lexeme: '',
    stack: Stack<ParseResult>(),
  );
  @override
  void accept(ElementVisitor visitor) {}
  @override
  String toString() => '[]';
}

OptionalSequence optionalSequence(ElementSequence elements) =>
    OptionalSequence(elements);

OptionalSequence optional(ElementSequence elements) =>
    OptionalSequence(elements);

/// Represents a negative lookahead assertion. Matches if the inner element fails.
/// Consumes no input.
final class NegativeLookahead implements Element {
  final Element element;
  @override
  final String? description;

  NegativeLookahead(this.element, {this.description});

  @override
  String toString() => '(?!$element)';

  @override
  ParseResult parse(String source) {
    final result = element.parse(source);
    if (!result.success) {
      return ParseResult(
        true,
        source, // consumes no input
        element: toString(),
        lexeme: '',
      );
    }
    return ParseResult(false, source, element: toString());
  }

  @override
  void accept(ElementVisitor visitor) => visitor.visitNegativeLookahead(this);
}

NegativeLookahead negativeLookahead(Element element, {String? description}) =>
    NegativeLookahead(element, description: description);

/// Represents alternative rules that can be matched (e.g., `foo / bar` in RFC 5234).
final class Alternatives implements Element {
  final ElementSequence elements;
  @override
  final String? description;

  Alternatives(this.elements, {this.description});

  @override
  String toString() =>
      elements.map((e) => e is Rule ? e.name : e.toString()).join(' / ');

  @override
  ParseResult parse(String source) {
    for (final element in elements) {
      final result = element.parse(source);
      if (result.success) {
        // Return the first successful match found.
        // Construct a new result attributed to this Alternatives rule,
        // pushing the successful sub-element's result onto its stack.
        final lexeme = source.substring(
          0,
          source.length - result.remaining.length,
        );
        return ParseResult(
          true,
          result.remaining,
          element: toString(),
          lexeme: lexeme,
          stack: Stack<ParseResult>()..push(result),
        );
      }
      // If result.success is false, we continue to the next alternative (backtracking).
    }

    // If no alternatives succeeded, return failure.
    return ParseResult(false, source, element: toString());
  }

  @override
  void accept(ElementVisitor visitor) => visitor.visitAlternatives(this);
}

Alternatives alternatives(Iterable<Element> elements) => Alternatives(elements);

/// Represents variable repetition of an element (e.g., `*foo` or `1*3foo`).
final class Repetition implements Element {
  final Element element;
  final int min;

  @override
  final String? description;

  // If [max] is null, infinity is the maximum
  final int? max;

  Repetition(this.element, {this.min = 0, this.max, this.description});

  @override
  String toString() {
    final buffer = StringBuffer();

    if (min == max) {
      buffer.write(min);
    } else {
      buffer.write(min > 0 ? '$min*' : '*');

      if (max != null) {
        buffer.write(max!);
      }
    }

    buffer.write('(${element is Rule ? (element as Rule).name : element})');
    return buffer.toString();
  }

  @override
  ParseResult parse(String source) {
    if (min > source.length) {
      return ParseResult(false, source);
    }

    final results = Stack<ParseResult>();

    var remaining = source;
    var count = 0;

    final upper = max;

    while (remaining.isNotEmpty && (upper == null || count < upper)) {
      final result = element.parse(remaining);
      results.push(result);
      if (result.success) {
        count++;
        remaining = result.remaining;
      } else {
        // If the inner element fails but we've met the minimum requirement,
        // we stop repeating and return success.
        if (count >= min) {
          break;
        }
        // Otherwise, the entire repetition fails.
        return ParseResult(false, source, stack: results, element: toString());
      }
    }

    if (count < min) {
      // Didn't get the lower limit of repetitions
      return ParseResult(false, remaining, stack: results, element: toString());
    }
    final String lexeme = source.substring(0, source.length - remaining.length);
    return ParseResult(
      true,
      remaining,
      stack: results,
      lexeme: lexeme,
      element: toString(),
    );
  }

  @override
  void accept(ElementVisitor visitor) => visitor.visitRepetition(this);
}

Repetition variableRepetition(Element value, {int min = 0, int? max}) =>
    Repetition(value, min: min, max: max);

Repetition repetition(Element value, int n) =>
    Repetition(value, min: n, max: n);

/// Represents a range of values (e.g., `%x41-5A`).
final class ValueRange implements Element {
  final int start;
  final int end;
  @override
  final String? description;

  ValueRange(this.start, this.end, {this.description});

  @override
  String toString() =>
      '%x${start.toRadixString(16).toUpperCase()}-${end.toRadixString(16).toUpperCase()}';

  AlternativeLiterals toAlternativeLiteral() {
    final alts = <String>[];

    for (int i = start; i <= end; i++) {
      alts.add(String.fromCharCode(i));
    }
    return alternativeLiterals(alts);
  }

  @override
  ParseResult parse(String source) {
    // Check if the source string is empty.
    if (source.isEmpty) {
      return ParseResult(false, source, element: toString());
    }

    final rune = source.runes.first;

    // Check if the 32-bit code point falls within the range.
    if (rune < start || rune > end) {
      return ParseResult(false, source, element: toString());
    }

    // Yield exactly one rune.
    final lexeme = String.fromCharCode(rune);
    return ParseResult(
      true,
      source.substring(lexeme.length),
      element: toString(),
      lexeme: lexeme,
    );
  }

  @override
  void accept(ElementVisitor visitor) => visitor.visitValueRange(this);
}

ValueRange valueRange(int start, int end) => ValueRange(start, end);

extension _ParseSequenceExtension on ElementSequence {
  /// Parses a sequence of elements using backtracking to support alternative paths.
  ///
  /// Backtracking is required when a sequence contains [Alternatives] that might
  /// match different lengths of the input source. If one path fails later in the
  /// sequence, this will backtrack and attempt other alternative paths.
  ParseResult _parseSequenceWithBacktracking(
    String source,
    String ruleDescription,
  ) {
    // Helper function to parse a subsequence starting from a given index
    ParseResult parseSubsequence(String currentSource, int startIndex) {
      final Stack<ParseResult> successfulResults = Stack();
      String remainingSource = currentSource;

      for (int i = startIndex; i < length; i++) {
        final element = elementAt(i);

        if (element is Alternatives || element is OptionalSequence) {
          final alternatives = element is Alternatives
              ? element.elements
              : (element as OptionalSequence).asAlternatives;
          bool alternativeMatched = false;
          for (final alternativeElement in alternatives) {
            final altResult = alternativeElement.parse(remainingSource);
            if (altResult.success) {
              // Try parsing the rest of the sequence with this alternative's result
              final restResult = parseSubsequence(altResult.remaining, i + 1);
              if (restResult.success) {
                // Found a valid path
                // Combine altResult and restResult into the main stack
                successfulResults.push(altResult);
                successfulResults.pushAll(restResult.stack);
                remainingSource = restResult.remaining;
                alternativeMatched = true;
                break; // Found a working alternative, stop trying others
              }
              // Backtrack: This alternative didn't work for the rest of the sequence
              // Continue to the next alternative
            }
          }
          if (!alternativeMatched) {
            // No alternative allowed the rest of the sequence to parse
            return ParseResult(
              false,
              source,
              element: ruleDescription,
              stack: Stack<ParseResult>()..pushAll(successfulResults),
            );
          }
        } else {
          // Regular element (not Alternatives)
          final result = element.parse(remainingSource);
          if (result.success) {
            successfulResults.push(result);
            remainingSource = result.remaining;
          } else {
            // If any non-alternative element fails, the concatenation fails
            return ParseResult(
              false,
              source,
              element: ruleDescription,
              stack: Stack<ParseResult>()..pushAll(successfulResults),
            );
          }
        }
      }

      // If we reached here, the subsequence (from startIndex) parsed successfully
      final String lexeme = source.substring(
        0,
        source.length - remainingSource.length,
      );
      return ParseResult(
        true,
        remainingSource,
        element: ruleDescription,
        lexeme: lexeme,
        stack: successfulResults,
      );
    }

    // Start parsing from the beginning of the sequence
    return parseSubsequence(source, 0);
  }
}
