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

import 'parse.dart';

/// A visitor function that is called for each node in the parse tree.
/// Return false to stop traversal, true to continue.
typedef ParseTreeVisitor = bool Function(ParseTreeNode node);

/// Represents a node in the parse tree with its full context
class ParseTreeNode {
  /// The parse result for this node
  final ParseResult result;

  /// The parent node, null for root
  final ParseTreeNode? parent;

  /// The depth of this node in the tree (0 = root)
  final int depth;

  ParseTreeNode(this.result, {this.parent, this.depth = 0});

  /// Get the lexeme (matched text) for this node
  String? get lexeme => result.lexeme;

  /// Get the rule name that created this node
  String? get ruleName => result.ruleName;

  /// Get the parser element name
  String? get element => result.element;

  /// Get all child nodes
  List<ParseTreeNode> get children {
    return result.stack
        .toList()
        .map((r) => ParseTreeNode(r, parent: this, depth: depth + 1))
        .toList();
  }

  /// Returns true if this node has any children
  bool get hasChildren => result.stack.isNotEmpty;

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write('  ' * depth);
    if (ruleName != null) sb.write('$ruleName: ');
    if (lexeme != null) sb.write('"$lexeme"');
    if (element != null) sb.write(' ($element)');
    if (!result.success) sb.write(' <FAILED>');
    return sb.toString();
  }
}

/// A walker that traverses a parse tree created by a successful parse
class ParseTreeWalker {
  /// The root node of the parse tree
  final ParseTreeNode root;

  /// Create a new walker from a successful parse result
  /// Throws if the parse result indicates failure
  ParseTreeWalker(ParseResult parseResult) : root = ParseTreeNode(parseResult);

  /// Visit all nodes in the tree in pre-order (parent before children)
  /// Returns false if traversal was stopped by the visitor
  bool visitPreOrder(ParseTreeVisitor visitor) {
    return _visitPreOrder(root, visitor);
  }

  bool _visitPreOrder(ParseTreeNode node, ParseTreeVisitor visitor) {
    if (!visitor(node)) return false;

    for (final child in node.children) {
      if (!_visitPreOrder(child, visitor)) return false;
    }

    return true;
  }

  /// Visit all nodes in the tree in post-order (children before parent)
  /// Returns false if traversal was stopped by the visitor
  bool visitPostOrder(ParseTreeVisitor visitor) {
    return _visitPostOrder(root, visitor);
  }

  bool _visitPostOrder(ParseTreeNode node, ParseTreeVisitor visitor) {
    for (final child in node.children) {
      if (!_visitPostOrder(child, visitor)) return false;
    }

    return visitor(node);
  }

  /// Find all nodes matching a given rule name
  List<ParseTreeNode> findByRuleName(String ruleName) {
    final matches = <ParseTreeNode>[];
    visitPreOrder((node) {
      if (node.ruleName == ruleName) matches.add(node);
      return true;
    });
    return matches;
  }

  /// Find the first node matching a given rule name
  ParseTreeNode? findFirstByRuleName(String ruleName) {
    ParseTreeNode? match;
    visitPreOrder((node) {
      if (node.ruleName == ruleName) {
        match = node;
        return false;
      }
      return true;
    });
    return match;
  }

  /// Get a string representation of the parse tree
  @override
  String toString() {
    final sb = StringBuffer();
    visitPreOrder((node) {
      sb.writeln(node.toString());
      return true;
    });
    return sb.toString();
  }
}
