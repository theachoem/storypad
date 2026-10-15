import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Called with a tapped link's URL, made launchable ([launchableLinkUrl]) -- e.g. to ask whether to open or copy it.
typedef LinkTapCallback = void Function(String url);

/// [url] with a scheme a launcher can open: as written when it has one (`https://…`, `mailto:…`, `tel:…`), `mailto:`
/// for an email address, otherwise `https://` -- so `example.com` opens, as it did in the Quill editor.
String launchableLinkUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.contains('://') || _schemeOnly.hasMatch(trimmed)) return trimmed;
  if (_emailAddress.hasMatch(trimmed)) return 'mailto:$trimmed';
  return 'https://$trimmed';
}

/// Schemes written without `//`.
final _schemeOnly = RegExp(r'^(mailto|tel|sms|geo|data):', caseSensitive: false);
final _emailAddress = RegExp(r'^[^\s@/]+@[^\s@/]+$');

/// Opens tapped links through [onTapLink] -- or, when it returns `null`, launches them like super_editor's own
/// handlers.
///
/// In the editor ([composer] given), links only respond in super_editor's "interaction mode" (Cmd/Ctrl held on
/// desktop), so a plain tap still places the caret for editing. In the reader, a tap opens the link.
class StoryLinkTapHandler extends ContentTapDelegate {
  StoryLinkTapHandler(this.document, this.onTapLink, {this.composer}) {
    composer?.isInInteractionMode.addListener(notifyListeners);
  }

  final Document document;
  final DocumentComposer? composer;

  /// Read at tap time, so the handler can outlive a rebuild with a new callback.
  final LinkTapCallback? Function() onTapLink;

  bool get _enabled => composer?.isInInteractionMode.value ?? true;

  @override
  void dispose() {
    composer?.isInInteractionMode.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  MouseCursor? mouseCursorForContentHover(DocumentPosition hoverPosition) {
    return _enabled && _linkAt(hoverPosition) != null ? SystemMouseCursors.click : null;
  }

  @override
  TapHandlingInstruction onTap(DocumentTapDetails details) {
    if (!_enabled) return TapHandlingInstruction.continueHandling;

    final position = details.documentLayout.getDocumentPositionNearestToOffset(details.layoutOffset);
    final link = position == null ? null : _linkAt(position);
    if (link == null) return TapHandlingInstruction.continueHandling;

    final callback = onTapLink();
    if (callback != null) {
      callback(launchableLinkUrl(link.plainTextUri));
    } else {
      final uri = Uri.tryParse(launchableLinkUrl(link.plainTextUri));
      if (uri != null) url_launcher.launchUrl(uri);
    }
    return TapHandlingInstruction.halt;
  }

  LinkAttribution? _linkAt(DocumentPosition position) {
    final nodePosition = position.nodePosition;
    if (nodePosition is! TextNodePosition) return null;
    final node = document.getNodeById(position.nodeId);
    if (node is! TextNode) return null;
    return node.text.getAllAttributionsAt(nodePosition.offset).whereType<LinkAttribution>().firstOrNull;
  }
}
