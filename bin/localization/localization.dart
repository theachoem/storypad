// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';

const String editUrl =
    "https://docs.google.com/spreadsheets/d/1XcohOqNzrkMJnAmAuJssa0Rc7wftjfN2rrxb4GgcE9c/edit?gid=654733603#gid=654733603";

const String publicCsvUrl =
    "https://docs.google.com/spreadsheets/d/e/2PACX-1vTlTQdinMVbZEL6EQzBs2zNtfldSnCtXA9YhegOe4CCoOA5FxXYmEp_t4joa_mIVgPVI5RaY_YNCGxa/pub?gid=654733603&single=true&output=csv";

void main() async {
  final csvString = await _fetchCsvRaw();
  final csvData = CsvToListConverter().convert(csvString);
  final transposedCsvData = _transposeCsv(csvData);

  if (await Directory('translations').exists()) {
    await Directory('translations').delete(recursive: true);
    await Directory('translations').create();
  }

  for (var i = 1; i < transposedCsvData.length; i++) {
    final locale = transposedCsvData[i][0];
    final file = File("translations/$locale.json");

    Map<String, String> map = {};

    for (var j = 0; j < transposedCsvData[i].length; j++) {
      final key = transposedCsvData[0][j];
      final value = transposedCsvData[i][j];
      map[key] = value;
    }

    await file.writeAsString(
      "${JsonEncoder.withIndent('  ').convert(map)}\n",
    );
  }
}

// Delete data.csv to refresh data from Google Drive.
Future<String> _fetchCsvRaw() async {
  final file = File('bin/localization/data.csv');

  if (await file.exists()) {
    return file.readAsString();
  }

  final response = await http.get(Uri.parse(publicCsvUrl));
  if (response.statusCode != 200) throw response.statusCode;

  final decodedBody = utf8.decode(response.bodyBytes);
  await file.writeAsString(decodedBody);

  return decodedBody;
}

List<List<dynamic>> _transposeCsv(List<List<dynamic>> rows) {
  List<List<dynamic>> transposed = [];

  for (int col = 0; col < rows[0].length; col++) {
    List<dynamic> newRow = [];
    for (int row = 0; row < rows.length; row++) {
      newRow.add(rows[row][col]);
    }
    transposed.add(newRow);
  }
  return transposed;
}
