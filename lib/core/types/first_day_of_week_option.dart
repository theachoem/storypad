enum FirstDayOfWeekOption {
  monday,
  sunday,
  ;

  static const defaultValue = FirstDayOfWeekOption.monday;

  int get value {
    switch (this) {
      case FirstDayOfWeekOption.monday:
        return 1;
      case FirstDayOfWeekOption.sunday:
        return 7;
    }
  }
}
