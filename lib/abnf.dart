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

/// Support for Augmented Backus-Naur Form (ABNF)
///
/// Refer to:
///
/// - [RFC 5234 - Augmented BNF for Syntax Specifications: ABNF](https://www.rfc-editor.org/info/rfc5234)
/// - [RFC 7405 - Case-Sensitive String Support in ABNF](https://www.rfc-editor.org/info/rfc7405)
library;

export 'src/core_rules.dart';
export 'src/grammar_printer.dart' show GrammarPrinter;
export 'src/grammar.dart';
export 'src/parse.dart' show ParseResult;
export 'src/parse_tree_walker.dart';
