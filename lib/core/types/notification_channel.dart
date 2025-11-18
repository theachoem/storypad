enum NotificationChannel {
  relaxingSound
  ;

  String get channelID {
    switch (this) {
      case relaxingSound:
        return 'relaxing_sounds';
    }
  }

  String get channelName {
    switch (this) {
      case relaxingSound:
        return 'Relaxing Music';
    }
  }
}
