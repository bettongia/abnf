Implementation of Augmented BNF for Syntax Specifications

## Features

This is a small package for those folks who get way too interested in the ABNF
found across so many RFCs.

It's likely that this isn't a fully featured or compliant implementation so
please feel free to lodge an issue if you hit something.

## Getting started

Take a look at the `example` directory for a few small examples to help you get
started:

- [basic.dart](example/basic.dart) is a simple example of setting up a grammar
  that allows only 2 lowercase letters.

  `dart run example/basic.dart`

- [content_type.dart](example/content_type.dart) is a partial implementation of
  the `Content-Type` header.

  `dart run example/content_type.dart`

## Usage

Define a grammar using the ABNF building blocks, then call `.parse()` on it:

```dart
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
```

## Additional information

Based on a provided ABNF syntax, parse input to determine if it is valid as well
as extract the parsed structure.

ABNF is described in:

- [RFC 5234 - Augmented BNF for Syntax Specifications: ABNF](https://www.rfc-editor.org/rfc/rfc5234)
- [RFC 7405 - Case-Sensitive String Support in ABNF](https://www.rfc-editor.org/rfc/rfc7405)
