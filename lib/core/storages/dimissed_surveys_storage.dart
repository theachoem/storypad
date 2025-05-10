import 'package:storypad/core/storages/base_object_storages/list_storage.dart';

// Survey URL will be remotely changed via remote config.
// User can click "No thank to dismissed" or take survey.
// Once they dismissed or took the survey, we add them to this list to avoid showing again.
class DimissedSurveysStorage extends ListStorage<String> {
  Future<void> add(String formURL) async {
    List<String>? result = await readList();

    result ??= [];
    result.add(formURL);

    await writeList(result);
  }
}
