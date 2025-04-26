class DaysCountInMonthService {
  static int get({
    required int year,
    required int month,
  }) {
    bool leapYear = (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));

    Map<int, int> dayCountByMonth = {
      DateTime.january: 31,
      DateTime.february: leapYear ? 29 : 28,
      DateTime.march: 31,
      DateTime.april: 30,
      DateTime.may: 31,
      DateTime.june: 30,
      DateTime.july: 31,
      DateTime.august: 31,
      DateTime.september: 30,
      DateTime.october: 31,
      DateTime.november: 30,
      DateTime.december: 31,
    };

    return dayCountByMonth[month]!;
  }
}
