// ignore_for_file: avoid_print

// This script imports translations from a JSON file into the main CSV file.
// It matches translations by key and preserves all existing data.
//
// Usage:
//   dart bin/localization/import_translations.dart <input_json> [locale_code]
//
// Example:
//   dart bin/localization/import_translations.dart translations/ru-RU.json ru
//   dart bin/localization/import_translations.dart translations/ja-JP.json ja

import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:csv/csv.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('Usage: dart bin/localization/import_translations.dart <input_json> [locale_code]');
    print('Example: dart bin/localization/import_translations.dart translations/ru-RU.json ru');
    exit(1);
  }

  final inputFile = File(arguments[0]);
  final localeCode = arguments.length > 1 ? arguments[1].toLowerCase() : null;
  final csvFile = File('bin/localization/data.csv');

  if (!await inputFile.exists()) {
    print('Error: Input file ${inputFile.path} does not exist');
    exit(1);
  }

  if (!await csvFile.exists()) {
    print('Error: CSV file ${csvFile.path} does not exist. Please run the build script first.');
    exit(1);
  }

  try {
    // Read and parse the JSON file
    final jsonContent = await inputFile.readAsString();
    final Map<String, dynamic> translations = json.decode(jsonContent);

    // Read and parse the CSV file
    final csvContent = await csvFile.readAsString();
    final csvData = const CsvToListConverter().convert(csvContent);

    if (csvData.isEmpty || csvData[0].isEmpty) {
      print('Error: Invalid CSV format');
      exit(1);
    }

    // Detect or determine the locale code
    final detectedLocale = localeCode ?? inputFile.path.split('/').last.split('.').first.split('-').first.toLowerCase();

    // Find the column index for this locale
    int localeCol = -1;
    for (int i = 0; i < csvData[0].length; i++) {
      if (csvData[0][i].toString().toLowerCase() == detectedLocale.toLowerCase()) {
        localeCol = i;
        break;
      }
    }

    // If locale not found, add it as a new column
    if (localeCol == -1) {
      print('Adding new locale: $detectedLocale');
      localeCol = csvData[0].length;
      // Add locale to header row
      csvData[0].add(detectedLocale);
      // Add empty cells for all other rows
      for (int i = 1; i < csvData.length; i++) {
        csvData[i].add('');
      }
    }

    // Create a map of existing keys to their row indices
    final keyToRow = <String, int>{};
    for (int i = 1; i < csvData.length; i++) {
      if (csvData[i].isNotEmpty && csvData[i][0] is String) {
        keyToRow[csvData[i][0]] = i;
      }
    }

    // Update or add translations
    int updated = 0;
    int added = 0;

    for (final entry in translations.entries) {
      final key = entry.key;
      final value = entry.value.toString();

      if (keyToRow.containsKey(key)) {
        // Update existing entry
        final row = keyToRow[key]!;
        if (csvData[row].length <= localeCol) {
          csvData[row].add(value);
        } else {
          csvData[row][localeCol] = value;
        }
        updated++;
      } else {
        // Add new entry
        final newRow = List.filled(csvData[0].length, '');
        newRow[0] = key;
        newRow[localeCol] = value;
        csvData.add(newRow);
        keyToRow[key] = csvData.length - 1;
        added++;
      }
    }

    // Write back to CSV
    final csv = const ListToCsvConverter().convert(csvData);
    await csvFile.writeAsString(csv);

    print('Import completed:');
    print('- Locale: $detectedLocale');
    print('- Updated: $updated translations');
    print('- Added: $added new keys');
    print('- Total keys in CSV: ${csvData.length - 1}');
  } catch (e) {
    print('Error processing files: $e');
    exit(1);
  }
}
