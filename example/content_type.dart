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

import 'package:betto_abnf/betto_abnf.dart';

/// Partial implementation of the ABNF grammar for the Content-Type Header Field
///
/// As provided in
/// [RFC 2045 - Section 5.1](https://www.rfc-editor.org/rfc/rfc2045#section-5.1)
final contentTypeGrammar = grammar('Content-Type', content);

/// content := "Content-Type" ":" type "/" subtype
final content = rule(
  'content',
  concatenation([
    literal('Content-Type'),
    literal(':'),
    optionalWsp,
    type,
    literal('/'),
    subtype,
  ]),
);

/// type := discrete-type / composite-type
final type = rule('type', alternativeLiterals(['text', 'image']));

// composite-type := "message" / "multipart"
final compositeType = rule(
  'composite-type',
  alternativeLiterals(['message', 'multipart']),
);

/// subtype := extension-token / iana-token
final subtype = rule(
  'subtype',
  alternativeLiterals(['plain', 'html', 'xml', 'png', 'jpeg', 'gif']),
);

void main() {
  final grammarPrinter = GrammarPrinter(contentTypeGrammar);

  // Print the ABNF grammar
  print('; Start of grammar');
  print(grammarPrinter);
  print('; End of grammar\n');

  print('----------');

  final input = 'Content-Type: text/plain';

  print('Input: $input');
  final parseResult = contentTypeGrammar.parse(input);
  print('Parse success: ${parseResult.success}');

  // Create a walker from a successful parse
  final walker = ParseTreeWalker(parseResult);

  // Print the full parse tree
  print('Parse tree:\n${walker.toString()}\n');

  print('----------');
}
