import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class SpQuillUnknownEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    return Text(tr("general.unknown"));
  }

  @override
  String get key => "unknown";
}
