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

/// ABNF core rules as defined in RFC 5234, Appendix B.1.
library;

import 'grammar.dart';

final alphaLower = rule('ALPHA-LOWER', valueRange(0x61, 0x7A));

final alphaUpper = rule('ALPHA-UPPER', valueRange(0x41, 0x5A));

final alpha = rule('ALPHA', alternatives([alphaLower, alphaUpper]));

final bit = rule('BIT', alternativeLiterals(['0', '1']));

final char = rule('CHAR', valueRange(0x01, 0xFF));

final cr = rule('CR', character(0x0D));

final crlf = rule('CRLF', Concatenation([cr, lf]));

/// Controls characters (range %x00-1F / %x7F).
final ctl = rule(
  'CTL',
  alternatives([valueRange(0x00, 0x1F), character(0x7f)]),
);

final digit = rule('DIGIT', valueRange(0x30, 0x39));

final alphanum = rule('ALPHANUM', alternatives([alpha, digit]));

final dquote = rule('DQUOTE', character(0x22));

final hexletters = rule(
  'HEX-LETTERS',
  // alternativeLiterals is case-insensitive by default (RFC 5234 §2.3),
  // so uppercase A–F are matched automatically.
  alternativeLiterals(['a', 'b', 'c', 'd', 'e', 'f']),
);

final hexdig = rule('HEXDIG', alternatives([hexletters, digit]));

final htab = rule('HTAB', character(0x09));

final lf = rule('LF', character(0x0A));

final sp = rule('SP', character(0x20));

/// Visible (printing) characters (range %x21-7E).
final vchar = rule('VCHAR', valueRange(0x21, 0x7E));

final wsp = rule('WSP', alternatives([sp, htab]));

final optionalWsp = rule('Optional-WSP', variableRepetition(wsp));
