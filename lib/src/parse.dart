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

import 'package:betto_common/collections.dart' show Stack, MappedObject;

/// The result of parsing an input string.
class ParseResult implements MappedObject {
  /// Whether the parse was successful.
  final bool success;

  /// The matched string, or null if there was no match (e.g., failed or optional match).
  final String? lexeme;

  /// The unparsed suffix of the input string.
  final String remaining;

  /// The name of the rule that produced this result, if any.
  final String? ruleName;

  /// A string representation of the parsed grammar element.
  final String? element;

  /// The hierarchical tree of child [ParseResult]s produced during this parse.
  final Stack<ParseResult> stack;

  /// Creates a [ParseResult].
  ///
  /// [success] indicates whether the sequence matched. [remaining] is the
  /// unconsumed portion of the source string. [lexeme] is the matched substring.
  /// [ruleName] and [element] provide debugging context. [stack] contains child
  /// parse results.
  ParseResult(
    this.success,
    this.remaining, {
    this.lexeme,
    this.ruleName,
    this.element,
    Stack<ParseResult>? stack,
  }) : stack = stack ?? Stack();

  @override
  Map<String, dynamic> toMap() => {
    'ruleName': ruleName,
    'success': success,
    'lexeme': lexeme,
    'remaining': remaining,
    'elementName': element,
    'stack': [for (final result in stack.toList()) result.toMap()],
  };

  /// Computes all lexemes for a given rule name in the parse tree.
  /// Uses a visited set to protect against infinite recursion if the
  /// parse tree contains cycles.
  List<String> getRuleLexemes(String ruleName) =>
      _getRuleLexemes(ruleName, <ParseResult>{});

  List<String> _getRuleLexemes(String ruleName, Set<ParseResult> visited) {
    if (visited.contains(this)) return const [];
    visited.add(this);

    final results = <String>[];
    for (final result in stack.toList()) {
      final lexeme = result.lexeme;
      if (result.ruleName == ruleName && lexeme != null) {
        results.add(lexeme);
      }
      results.addAll(result._getRuleLexemes(ruleName, visited));
    }
    return results;
  }
}
