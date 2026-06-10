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

// A very basic parser that just wants 2 lowercase characters
void main() {
  final g = grammar(
    'iso-639-1-language',
    rule('language', repetition(alphaLower, 2)),
  );

  print('Grammar: ${GrammarPrinter(g)}');

  print('Parse result for "en": ${g.parse('en').success}');
  print('Parse result for "EN": ${g.parse('EN').success}');
  print('Parse result for "en-US": ${g.parse('en-US').success}');

  // Create a walker from a successful parse of 'en'
  final result = g.parse('en');

  final walker = ParseTreeWalker(result);
  // Print the full parse tree
  print('Parse tree:\n${walker.toString()}\n');

  // We can access a specific rule
  print('Rule lexemes for "language": ${result.getRuleLexemes('language')}');
}
