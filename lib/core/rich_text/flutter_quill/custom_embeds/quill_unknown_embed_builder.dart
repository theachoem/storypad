part of '../quill_adapter.dart';

class _QuillUnknownEmbedBuilder extends quill.EmbedBuilder {
  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    return Text(tr("general.unknown"));
  }

  @override
  String get key => "unknown";
}
