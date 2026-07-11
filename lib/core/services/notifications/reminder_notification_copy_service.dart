import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Picks varied English notification copy for the built-in reminders so the
/// same text doesn't show up every single day. Other languages keep today's
/// single translated string — mirrors `WelcomeMessageService`
/// (lib/core/services/welcome_message_service.dart), which does the same for
/// the home greeting for the same reason (untranslated variants would make
/// the app feel unfinished in other languages).
///
/// Unlike `WelcomeMessageService`, this can't rely on `context.locale` —
/// reminder scheduling runs from `RootProvider` (a ChangeNotifier, not a
/// widget), so there's no BuildContext to read it from. Instead it reads the
/// locale easy_localization itself persisted to SharedPreferences under the
/// key `'locale'` (see EasyLocalizationController), which is the same source
/// `context.locale` is initialized from.
class ReminderNotificationCopyService {
  static Future<bool> _useEnglishVariants() async {
    final prefs = await SharedPreferences.getInstance();
    final locale = prefs.getString('locale');
    return locale == null || locale.startsWith('en');
  }

  /// One title+body pair, kept together so tone always matches — never
  /// mix-and-match a random title with an unrelated random body.
  static Future<(String title, String body)> dailyCopy() =>
      _pick(_daily, 'reminder.daily.notification_title', 'reminder.daily.notification_body');

  static Future<(String title, String body)> onThisDayCopy() => _pick(
    _onThisDay,
    'reminder.on_this_day.notification_title',
    'reminder.on_this_day.notification_body',
  );

  static Future<(String title, String body)> periodCopy() =>
      _pick(_period, 'reminder.period.notification_title', 'reminder.period.notification_body');

  static Future<(String, String)> _pick(
    List<(String, String)> variants,
    String fallbackTitleKey,
    String fallbackBodyKey,
  ) async {
    if (!await _useEnglishVariants()) return (tr(fallbackTitleKey), tr(fallbackBodyKey));
    return variants[Random().nextInt(variants.length)];
  }

  static const List<(String, String)> _daily = [
    ("Time to write ✍️", "Take a moment to capture your day."),
    ("Hey, got a minute?", "Your journal is waiting for today's story."),
    ("Dear diary…", "What happened today? Jot it down before you forget."),
    ("A little reflection?", "Even a few lines count. What's on your mind?"),
    ("Today's story awaits", "Every day is worth remembering — write yours."),
    ("Quick check-in", "How are you feeling right now? Write it down."),
    ("Capture today", "Future you will thank you for writing this down."),
    ("Journal time 📓", "A few sentences today is all it takes."),
    ("Still time to write", "Don't let today slip by unwritten."),
    ("One line is enough", "You don't need much — just start."),
    ("What made you smile today?", "Small moments make the best entries."),
    ("Your day, your words", "Nobody tells your story better than you."),
    ("Keep the streak going", "Add today's entry to your journal."),
    ("Pause and reflect", "Write down what today felt like."),
    ("Before you sleep…", "Capture today while it's still fresh."),
    ("Write it down", "Today happened — make sure you remember it."),
    ("A moment for you", "Take five minutes to write about your day."),
    ("Something worth keeping?", "Turn today into a memory you can revisit."),
    ("New entry?", "Your journal has room for one more story."),
    ("Just checking in", "What's one thing from today you want to remember?"),
  ];

  static const List<(String, String)> _onThisDay = [
    ("On this day", "See what you wrote on this day."),
    ("A memory awaits", "You have entries from this day in years past."),
    ("Look back", "Curious what you were up to on this day before?"),
    ("Throwback time", "Revisit your past entries from this exact date."),
    ("Remember this day?", "Take a peek at what you wrote before."),
    ("Your past self says hi", "See your memories from this day."),
    ("History repeats", "This day has stories from your journal's past."),
    ("A little nostalgia", "Reflect on what this day meant before."),
    ("Same day, different year", "Check out your past entries for today."),
    ("Worth revisiting", "You wrote something on this day — take a look."),
    ("Then and now", "Compare today with how you felt back then."),
    ("A page from the past", "Your journal remembers this day — do you?"),
    ("Time capsule 📬", "Open a memory from this day in previous years."),
    ("This day, before", "See how far you've come since then."),
    ("Flashback", "Your past entries for this date are ready to revisit."),
    ("You wrote this once", "Take a moment to reread your past entry."),
    ("On this date…", "Your journal has something to show you."),
    ("Full circle", "This day has meaning in your journal's history."),
    ("Look who's back", "This day again — see what you once wrote."),
    ("A story from before", "Revisit your memory from this same day."),
  ];

  static const List<(String, String)> _period = [
    ("Period reminder", "Your next period may be coming soon."),
    ("Heads up", "Your cycle suggests your period is approaching."),
    ("Time to prepare", "Your period might start in the next few days."),
    ("Cycle check-in", "Based on your history, your period may be near."),
    ("Be prepared", "Your predicted period date is coming up."),
    ("A gentle nudge", "Your period may arrive soon — plan ahead."),
    ("Cycle update", "Your next period is expected shortly."),
    ("Stay ahead", "It might be time to get ready for your period."),
    ("Coming soon", "Your period is predicted to start in a few days."),
    ("Just a heads-up", "Time to stock up — your period may be near."),
    ("Your body's calendar", "Your next period could be just around the corner."),
    ("Plan ahead", "Your predicted cycle suggests your period is close."),
    ("Prediction alert", "Your period may begin in the coming days."),
    ("Cycle reminder", "Based on past cycles, your period could start soon."),
    ("Get ready", "It's almost time for your predicted period."),
    ("Your cycle, tracked", "Your next period is estimated to be near."),
    ("A quick reminder", "Your period might be approaching soon."),
    ("Stay on top of it", "Your predicted period date is coming up."),
    ("Cycle awareness", "It may be time to prepare for your period."),
    ("Your next cycle", "Your period is expected around this time."),
  ];
}
