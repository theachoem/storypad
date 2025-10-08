import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// Only return random message for english, other language translation are not match the the phrase & make app feel unfinished.
class WelcomeMessageService {
  static int? _index;

  static String get(BuildContext context) {
    if (context.locale.languageCode != 'en') return tr('page.home.app_bar.messages.what_in_ur_mind');

    final messages = {
      "Let your adventure unfold with every word you write.",
      "Your story unfolds one thought at a time.",
      "Capture this moment.",
      "Dream it. Write it.",
      "Anything exciting today?",
      "Are today's feelings worth writing down?",
      "What feelings move you today?",
      "What's on the next page of your journey?",
      "What would you tell your future self?",
      "What's today's highlight?",
      "Jot it down before it fades.",
      "No pressure, just write.",
      "Let your words flow.",
      "Make everyday moments extraordinary.",
      "What's a moment you'll never forget?",
      "A new page, a new beginning.",
      "The page is open, waiting for you.",
      "Express yourself truthfully.",
      "What's on your heart?",
      "Allow your thoughts to grow.",
      "Start with a word.",
      "Your story continues here.",
      "Let your thoughts lead.",
      "Today's thoughts, tomorrow's memories.",
      "Let your mind wander.",
      "What's on your mind?",
      "Here, your words are safe.",
      "Your diary, your rules.",
      "This is your space, make it yours.",
      "Tell your story, no one else can.",
      "It's okay not to be perfect.",
    };

    _index ??= Random().nextInt(messages.length);
    return messages.elementAt(_index!);
  }
}
