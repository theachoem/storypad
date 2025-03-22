import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class WelcomeMessageService {
  static int? _index;

  static String get(BuildContext? context) {
    final messages = {
      tr("page.home.app_bar.messages.what_in_ur_mind", context: context),
      tr("page.home.app_bar.messages.your_story", context: context),
      tr("page.home.app_bar.messages.new_page", context: context),
      tr("page.home.app_bar.messages.let_it_flow", context: context),
      tr("page.home.app_bar.messages.capture_moment", context: context),
      tr("page.home.app_bar.messages.adventure_awaits", context: context),
      tr("page.home.app_bar.messages.thoughts_lead", context: context),
      tr("page.home.app_bar.messages.dream_it", context: context),
      tr("page.home.app_bar.messages.start_word", context: context),
      tr("page.home.app_bar.messages.exciting_today", context: context),
      tr("page.home.app_bar.messages.story_here", context: context),
      tr("page.home.app_bar.messages.write_freely", context: context),
      tr("page.home.app_bar.messages.seed_grow", context: context),
      tr("page.home.app_bar.messages.feelings_now", context: context),
      tr("page.home.app_bar.messages.jot_it_down", context: context),
      tr("page.home.app_bar.messages.fresh_page", context: context),
      tr("page.home.app_bar.messages.memory_today", context: context),
      tr("page.home.app_bar.messages.your_rules", context: context),
      tr("page.home.app_bar.messages.big_ideas", context: context),
      tr("page.home.app_bar.messages.wander_free", context: context),
      tr("page.home.app_bar.messages.raw_real", context: context),
      tr("page.home.app_bar.messages.today_memory", context: context),
      tr("page.home.app_bar.messages.future_self", context: context),
      tr("page.home.app_bar.messages.just_write", context: context),
      tr("page.home.app_bar.messages.highlight_today", context: context),
      tr("page.home.app_bar.messages.your_space", context: context),
      tr("page.home.app_bar.messages.magic_words", context: context),
      tr("page.home.app_bar.messages.feelings_flow", context: context),
      tr("page.home.app_bar.messages.say_something", context: context),
      tr("page.home.app_bar.messages.page_waiting", context: context),
    };

    _index ??= Random().nextInt(messages.length);
    return messages.elementAt(_index!);
  }
}
