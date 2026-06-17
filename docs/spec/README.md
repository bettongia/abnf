---
title: Technical Specification
subtitle: betto_abnf
toc-title: "Contents"
...

- **Package:** `betto_abnf`
- **Version:** 0.1.0
- **Dart SDK:** ≥ 3.12.0

## 1. Purpose

`betto_abnf` is a pure-Dart library for defining and parsing grammars expressed
in Augmented Backus-Naur Form (ABNF). It allows callers to construct a grammar
programmatically from composable `Element` values, parse an input string against
that grammar, and walk the resulting parse tree to extract matched lexemes.

The library does not parse ABNF text — it provides a Dart DSL that mirrors the
ABNF notation.

## 2. Standards

| Standard | Coverage |
|---|---|
| [RFC 5234](https://www.rfc-editor.org/rfc/rfc5234) — ABNF for Syntax Specifications | Core element model and all Appendix B.1 core rules |
| [RFC 7405](https://www.rfc-editor.org/rfc/rfc7405) — Case-Sensitive String Support | `%s` / `%i` prefixes via `caseSensitive` flag |

The implementation is intended to be practically useful, not a formally verified
reference implementation. Known limitations should be tracked as issues.

## 3. Grammar Element Model

All grammar constructs are subtypes of the sealed class `Element`:

```
Element (sealed)
├── Grammar            – top-level entry point wrapping a root Rule
├── Rule               – named rule binding a name to an Element
├── LiteralElement     – case-insensitive (default) or case-sensitive string
├── AlternativeLiterals– optimised set of string alternatives (RFC 5234 §3.4)
├── CharacterElement   – single Unicode code point (%xNN)
├── ValueRange         – contiguous code point range (%xNN-MM)
├── Alternatives       – ordered choice (foo / bar)
├── Concatenation      – ordered sequence (foo bar), with backtracking
├── Sequence           – internal ordered sequence (same semantics)
├── Group              – parenthesised sequence ( foo bar )
├── OptionalSequence   – optional bracket group [ foo bar ]
├── Repetition         – bounded/unbounded repetition (*foo, 1*3foo, 2foo)
├── EmptyElement       – always succeeds, consumes nothing (empty option arm)
└── NegativeLookahead  – succeeds if inner element fails; consumes no input
```

Every `Element` exposes:

- `ParseResult parse(String source)` — attempt to match the head of `source`.
- `void accept(ElementVisitor visitor)` — double-dispatch for the visitor pattern.
- `String? description` — optional human-readable label.

### 3.1 Factory Functions

Callers build grammars using lowercase factory functions rather than
constructors directly (constructors are `@Deprecated`):

```dart
grammar(name, entryRule)
rule(name, element)
literal(value)                   // case-insensitive (RFC 5234 default)
caseSensitiveLiteral(value)      // case-sensitive (%s prefix, RFC 7405)
alternativeLiterals(values)      // case-insensitive set
caseSensitiveAlternativeLiterals(values)
character(codePoint)             // single %xNN
valueRange(start, end)           // %xNN-MM
alternatives(elements)           // foo / bar
concatenation(elements)          // foo bar
group(elements)                  // (foo bar)
optional(elements)               // [foo bar]
optionalSequence(elements)       // alias for optional()
repetition(element, n)           // exactly n times
variableRepetition(element,      // *foo, 1*foo, 1*3foo
    min: 0, max: null)
negativeLookahead(element)
```

### 3.2 Case Sensitivity

`LiteralElement` and `AlternativeLiterals` are **case-insensitive by default**,
matching RFC 5234 §2.3. Pass `caseSensitive: true` (or use the
`caseSensitive*` factories) to opt into RFC 7405 `%s` semantics.

### 3.3 AlternativeLiterals Optimisation

When all candidate strings have the same grapheme cluster length the parser uses
a single fixed-width slice comparison. When lengths differ ("jagged") it falls
back to longest-first ordered matching to ensure greedy behaviour.

### 3.4 Backtracking

`Concatenation` and `Sequence` perform recursive backtracking when an element is
`Alternatives` or `OptionalSequence`. If one alternative succeeds but a later
element in the sequence fails, the parser retries with the next alternative.
Plain `Rule`, `Literal`, `ValueRange`, and `Repetition` elements do not
backtrack.

### 3.5 Unicode

Code points are handled via Dart's `runes` API and the `characters` package.
`CharacterElement` and `ValueRange` match a single Unicode code point (32-bit).
`AlternativeLiterals` length comparisons use grapheme cluster counts.

## 4. Core Rules

`core_rules.dart` provides pre-built `Rule` instances matching RFC 5234
Appendix B.1:

| Name | Description |
|---|---|
| `alpha` | Letters A–Z / a–z |
| `alphaLower` / `alphaUpper` | Lower / upper case only |
| `alphanum` | Letters and digits |
| `bit` | `0` or `1` |
| `char` | Any US-ASCII character |
| `cr` / `lf` / `crlf` | Carriage return / line feed / both |
| `ctl` | Control characters |
| `digit` | Decimal digits 0–9 |
| `dquote` | Double-quote character |
| `hexdig` / `hexletters` | Hex digit / hex letter (case-insensitive) |
| `htab` | Horizontal tab |
| `sp` | Space |
| `vchar` | Visible printing characters |
| `wsp` / `optionalWsp` | Whitespace / optional whitespace |

## 5. Parse Result and Tree

### 5.1 ParseResult

```dart
class ParseResult {
  bool    success;    // true if the element matched
  String? lexeme;     // the matched substring (null on failure)
  String  remaining;  // unconsumed tail of the input
  String? ruleName;   // name of the Rule that produced this result
  String? element;    // toString() of the element (debugging)
  Stack<ParseResult> stack; // child results
}
```

`Grammar.parse()` enforces full consumption: if `remaining` is non-empty after
the entry rule matches, the overall result is `false`.

`ParseResult.getRuleLexemes(ruleName)` traverses the stack recursively and
returns all lexemes that were matched by a rule of the given name.

### 5.2 ParseTreeWalker

`ParseTreeWalker` wraps a `ParseResult` and provides structured tree traversal:

- `visitPreOrder(visitor)` — parent before children
- `visitPostOrder(visitor)` — children before parent
- `findByRuleName(name)` — all matching nodes
- `findFirstByRuleName(name)` — first matching node

`ParseTreeNode` exposes `lexeme`, `ruleName`, `element`, `depth`, `parent`, and
`children`.

## 6. GrammarPrinter

`GrammarPrinter` implements `ElementVisitor` and walks a `Grammar` to produce a
human-readable ABNF listing. It deduplicates rules (each rule name is emitted
once) and aligns definitions using the longest rule name as a column width.

```dart
print(GrammarPrinter(myGrammar)); // writes aligned ABNF text
```

A custom `printerFunction` can be supplied to format the `Map<String, String>`
of rule names to definitions in any other way.

## 7. Dependencies

| Package | Role |
|---|---|
| `betto_common` | `Stack<T>` and `MappedObject` utilities |
| `characters` | Unicode grapheme cluster counting for `AlternativeLiterals` |
