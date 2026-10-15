import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/widgets/rich_editor/sp_editor_controller.dart';

class StoryPageObject {
  final GlobalKey key;
  final SpEditorController bodyController;
  final FocusNode bodyFocusNode;

  StoryPageDbModel _page;

  // [_page] is behind the editor.
  bool _stale = false;

  // The story's content doesn't have this page's latest edit yet (see [takeEdit]).
  bool _pendingEdit = false;

  // The editor's document revision [_page] and the story's content were last brought up to. An edit is also noticed
  // by the revision, not only [markEdited] -- which needs the page's editor on screen, while its toolbar can still edit
  // it after it scrolled away (e.g. adding a photo once swiped to the next page).
  int _readRevision;
  int _takenRevision;

  int get _revision => bodyController.editor.documentRevision.value;

  /// The page as stored. After an edit (see [markEdited]) it's read from the editor the first time it's needed -- a
  /// save, Done, leaving -- rather than on every keystroke.
  StoryPageDbModel get page {
    if (_stale || _revision != _readRevision) {
      _stale = false;
      _readRevision = _revision;
      _page = _page.withMarkdown(bodyController.serialize());
    }
    return _page;
  }

  set page(StoryPageDbModel value) {
    _page = value;
    _stale = false;
    _pendingEdit = false;
    _readRevision = _takenRevision = _revision;
  }

  /// Whether the page is in a format from a newer app version (read-only). Editing never changes it, so it's read
  /// without [page] (which would read the page from its editor after an edit).
  bool get isUnsupported => _page.isUnsupported;

  /// Whether the page was edited since the story's content last took it (see [takeEdit]).
  bool get hasPendingEdit => _pendingEdit || _revision != _takenRevision;

  /// The editor's content changed: [page] reads it from the editor when next read.
  void markEdited() => _stale = _pendingEdit = true;

  /// The edited [page], for the story's content, which now has it.
  StoryPageDbModel takeEdit() {
    _pendingEdit = false;
    _takenRevision = _revision;
    return page;
  }

  // set from UI during interaction.
  // Use to check whether the page's top (where its title is) is visible.
  // The first page with its top visible gets the focus when moving to the edit page.
  double? titleVisibleFraction;

  int get id => _page.id;

  StoryPageObject({
    required this.key,
    required StoryPageDbModel page,
    required this.bodyController,
    required this.bodyFocusNode,
  }) : _page = page,
       _readRevision = bodyController.editor.documentRevision.value,
       _takenRevision = bodyController.editor.documentRevision.value;

  void dispose() {
    bodyController.dispose();
    bodyFocusNode.dispose();
  }
}
