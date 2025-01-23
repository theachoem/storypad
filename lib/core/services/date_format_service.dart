// ignore_for_file: non_constant_identifier_names, depend_on_referenced_packages

import 'package:intl/intl.dart';

class DateFormatService {
  static String E(DateTime date) {
    return DateFormat.E().format(date);
  }

  static String MMM(DateTime date) {
    return DateFormat.MMM().format(date);
  }

  static String yMEd_jm(DateTime date) {
    return DateFormat.yMEd().addPattern("- ${DateFormat.jm().pattern!}").format(date);
  }

  static String? yMEd_jmNullable(DateTime? date) {
    if (date == null) return null;
    return DateFormat.yMEd().addPattern("- ${DateFormat.jm().pattern!}").format(date);
  }

  static String? yMEdNullable(DateTime? date) {
    if (date == null) return null;
    return DateFormat.yMEd().format(date);
  }

  static String yMEd(DateTime date) {
    return DateFormat.yMEd().format(date);
  }

  static String jms(DateTime date) {
    return DateFormat.jms().format(date);
  }

  static String yMd(DateTime date) {
    return DateFormat.yMd().format(date);
  }

  static String yM(DateTime date) {
    return DateFormat.yM().format(date);
  }
}
