import 'dart:math';
import 'package:easy_localization/easy_localization.dart';

class WelcomeMessageService {
  static int? _index;

  static String get() {
    final messages = {
      tr("page.home.app_bar.messages.what_in_ur_mind"),
      tr("page.home.app_bar.messages.your_story"),
      tr("page.home.app_bar.messages.new_page"),
      tr("page.home.app_bar.messages.let_it_flow"),
      tr("page.home.app_bar.messages.capture_moment"),
      tr("page.home.app_bar.messages.adventure_awaits"),
      tr("page.home.app_bar.messages.thoughts_lead"),
      tr("page.home.app_bar.messages.dream_it"),
      tr("page.home.app_bar.messages.start_word"),
      tr("page.home.app_bar.messages.exciting_today"),
      tr("page.home.app_bar.messages.story_here"),
      tr("page.home.app_bar.messages.write_freely"),
      tr("page.home.app_bar.messages.seed_grow"),
      tr("page.home.app_bar.messages.feelings_now"),
      tr("page.home.app_bar.messages.jot_it_down"),
      tr("page.home.app_bar.messages.fresh_page"),
      tr("page.home.app_bar.messages.memory_today"),
      tr("page.home.app_bar.messages.your_rules"),
      tr("page.home.app_bar.messages.big_ideas"),
      tr("page.home.app_bar.messages.wander_free"),
      tr("page.home.app_bar.messages.raw_real"),
      tr("page.home.app_bar.messages.today_memory"),
      tr("page.home.app_bar.messages.future_self"),
      tr("page.home.app_bar.messages.just_write"),
      tr("page.home.app_bar.messages.highlight_today"),
      tr("page.home.app_bar.messages.your_space"),
      tr("page.home.app_bar.messages.magic_words"),
      tr("page.home.app_bar.messages.feelings_flow"),
      tr("page.home.app_bar.messages.say_something"),
      tr("page.home.app_bar.messages.page_waiting"),
    };

    _index ??= Random().nextInt(messages.length);
    return messages.elementAt(_index!);
  }
}
