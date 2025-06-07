import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';

class BackupPreferencesTableViewer extends StatelessWidget {
  const BackupPreferencesTableViewer({
    super.key,
    required this.preferences,
  });

  final List<PreferenceDbModel> preferences;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: preferences.length,
      itemBuilder: (context, index) {
        final preference = preferences[index];
        return ListTile(
          title: Text(preference.key),
          subtitle: Text(preference.value),
        );
      },
    );
  }
}
