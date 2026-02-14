import 'package:flutter/widgets.dart';

/// Context data passed to embed builders during rendering
class RichTextEmbedContext {
  /// The controller managing this editor instance
  final dynamic controller;

  /// Whether the editor is in read-only mode
  final bool readOnly;

  /// The embed node data
  final RichTextEmbedNode node;

  const RichTextEmbedContext({
    required this.controller,
    required this.readOnly,
    required this.node,
  });
}

/// Represents an embed node in the document
///
/// Contains:
/// - Embed type (image, audio, date, etc.)
/// - Embed data (file path, configuration, etc.)
/// - Position in document
class RichTextEmbedNode {
  /// Type of embed (e.g., 'image', 'audio', 'date')
  final String type;

  /// Embed-specific data
  final dynamic data;

  /// Position in document (character offset)
  final int documentOffset;

  /// Length of embed in document (usually 1)
  final int length;

  /// Custom attributes for this embed (alignment, size, etc.)
  final Map<String, dynamic> attributes;

  const RichTextEmbedNode({
    required this.type,
    required this.data,
    required this.documentOffset,
    required this.length,
    this.attributes = const {},
  });

  /// Applies a custom attribute to this embed
  void applyAttribute(String key, dynamic value) {
    // Implementation depends on underlying editor
    // This is a placeholder for the interface
  }

  /// Gets attribute value by key
  dynamic getAttribute(String key) => attributes[key];

  /// Serializes embed to JSON format
  Map<String, dynamic> toJson() => {
    type: data,
    'attributes': attributes,
  };
}

/// Abstract base class for custom embed builders.
///
/// Embed builders render custom content blocks in the rich text editor:
/// - Images
/// - Audio/video players
/// - Dates
/// - Custom widgets
///
/// Implementations should:
/// 1. Define the embed type key
/// 2. Build a widget for the embed
/// 3. Handle user interactions (if not read-only)
abstract class RichTextEmbedBuilder {
  /// The unique key identifying this embed type
  ///
  /// Examples: 'image', 'audio', 'date', 'video'
  String get key;

  /// Builds the widget for this embed
  ///
  /// [context] provides access to:
  /// - Controller for editor operations
  /// - Read-only state
  /// - Embed node data
  Widget build(BuildContext context, RichTextEmbedContext embedContext);
}

/// Special embed builder for handling unknown/unsupported embed types
///
/// Used as fallback when embed type is not registered
abstract class RichTextUnknownEmbedBuilder extends RichTextEmbedBuilder {
  @override
  String get key => '__unknown__';

  /// Builds a fallback widget for unknown embeds
  ///
  /// Typically shows a placeholder or error message
  @override
  Widget build(BuildContext context, RichTextEmbedContext embedContext);
}
