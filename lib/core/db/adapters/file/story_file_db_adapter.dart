part of 'package:spooky/core/db/databases/story_database_deprecated.dart';

class _StoryFileDbAdapter extends BaseFileDbAdapter implements BaseStoryDbExternalActions {
  _StoryFileDbAdapter(String tableName) : super(tableName);

  String dirPath({
    required String? type,
  }) {
    String prefix = "database/file";

    String path = [
      FileHelper.directory.absolute.path,
      prefix,
      tableName,
      if (type != null) type,
    ].join("/");

    return path;
  }

  Future<Directory> buildDir({
    required String? type,
  }) async {
    Directory directory = Directory(dirPath(type: type));
    await ensureDirExist(directory);
    return directory;
  }

  Future<Directory> buildFileParentDir({
    required int? year,
    required int? month,
    required int? day,
    required String? type,
  }) async {
    Directory prefix = await buildDir(type: type);
    List<String> paths = [
      prefix.path,
      if (year != null) "$year",
      if (month != null) "$month",
      if (day != null) "$day",
    ];

    String path = paths.join("/");
    Directory directory = Directory(path);
    return directory;
  }

  Future<File> buildFile({
    required int year,
    required int month,
    required int day,
    required String type,
    required int id,
  }) async {
    Directory prefix = await buildFileParentDir(year: year, month: month, day: day, type: type);
    String fileName = "$id.json";
    String path = "${prefix.path}/$fileName";
    File file = File(path);
    await ensureFileExist(file);
    return file;
  }

  @override
  Future<Map<String, dynamic>?> set({
    Map<String, dynamic> body = const {},
    Map<String, dynamic> params = const {},
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> create({
    Map<String, dynamic> body = const {},
    Map<String, dynamic> params = const {},
  }) async {
    StoryDbModel story = StoryDbModel.fromJson(body);
    String json = AppHelper.prettifyJson(story.toJson());

    File file = await buildFile(
      year: story.year,
      month: story.month,
      day: story.day,
      type: story.type.name,
      id: story.id,
    );

    file = await file.writeAsString(json);
    return fetchOne(id: story.id);
  }

  @override
  Future<Map<String, dynamic>?> delete({
    required int id,
    Map<String, dynamic> params = const {},
  }) async {
    String? type = params["type"];
    int? year = params["year"];
    int? month = params["month"];
    int? day = params["day"];

    if (type == null) throw ErrorMessage(errorMessage: "Path type must not null");
    if (year == null) throw ErrorMessage(errorMessage: "Year must not null");
    if (month == null) throw ErrorMessage(errorMessage: "Month must not null");
    if (day == null) throw ErrorMessage(errorMessage: "Day must not null");

    Directory directory = await buildFileParentDir(year: year, month: month, day: day, type: type);
    List<FileSystemEntity> list = directory.listSync(recursive: true);
    for (FileSystemEntity element in list) {
      if (element.path.endsWith("$id.json") && element is File) {
        await element.delete();
      }
    }

    return fetchOne(id: id);
  }

  @override
  Future<Map<String, dynamic>?> fetchAll({
    Map<String, dynamic>? params,
  }) async {
    String? type = params?["type"];
    int? year = params?["year"];
    int? month = params?["month"];
    int? day = params?["day"];

    Directory directory = await buildFileParentDir(year: year, month: month, day: day, type: type);
    if (directory.existsSync()) {
      List<FileSystemEntity> entities = directory.listSync(recursive: true);
      List<Map<String, dynamic>> docs = [];

      for (FileSystemEntity item in entities) {
        if (item is File && item.absolute.path.endsWith(".json")) {
          Map<String, dynamic>? json = await fetchOne(id: 0, params: {"file": item});
          if (json != null) {
            dynamic id = basename(item.path).split(".")[0];
            json['id'] = int.tryParse(id) ?? json['id'];
            docs.add(json);
          }
        }
      }

      return {
        "data": docs,
        "meta": MetaModel().toJson(),
        "links": MetaModel().toJson(),
      };
    }

    return null;
  }

  @override
  Future<Map<String, dynamic>?> fetchOne({
    required int id,
    Map<String, dynamic>? params,
  }) async {
    File? file = params?['file'];

    // id is unnecessary when file != null
    if (file != null) {
      String result = await file.readAsString();
      dynamic json = jsonDecode(result);
      if (json is Map<String, dynamic>) return json;
    } else {
      Directory directory = await buildDir(type: null);
      List<FileSystemEntity> list = directory.listSync(recursive: true);

      for (FileSystemEntity file in list) {
        if (file.path.endsWith("$id.json") && file is File) {
          String result = await file.readAsString();
          dynamic json = jsonDecode(result);
          if (json is Map<String, dynamic>) return json;
        }
      }
    }

    return null;
  }

  @override
  Future<Map<String, dynamic>?> update({
    required int id,
    Map<String, dynamic> body = const {},
    Map<String, dynamic> params = const {},
  }) async {
    StoryDbModel story = StoryDbModel.fromJson(body).copyWith(updatedAt: DateTime.now());
    Directory directory = await buildDir(type: story.type.name);
    File? fileToUpdate;

    List<FileSystemEntity> list = directory.listSync(recursive: true);
    for (FileSystemEntity element in list) {
      if (element.path.endsWith("$id.json") && element is File) {
        fileToUpdate = element;
        break;
      }
    }

    if (fileToUpdate != null) {
      String json = AppHelper.prettifyJson(story.toJson());
      fileToUpdate = await fileToUpdate.writeAsString(json);

      File file = await buildFile(
        year: story.year,
        month: story.month,
        day: story.day,
        type: story.type.name,
        id: story.id,
      );

      File? updatedFile = await move(fileToUpdate, file.path);
      return fetchOne(
        id: story.id,
        params: {'file': updatedFile},
      );
    } else {
      throw ErrorMessage(errorMessage: "ID: $id not found");
    }
  }

  @override
  Future<Set<int>?> fetchYears() async {
    Directory docsPath = Directory(dirPath(type: PathType.docs.name));
    if (await docsPath.exists()) {
      await ensureDirExist(docsPath);

      List<FileSystemEntity> result = docsPath.listSync();
      Set<String> years = result.map((e) {
        return e.absolute.path.split("/").last;
      }).toSet();

      Set<int> yearsInt = {};
      for (String e in years) {
        int? y = int.tryParse(e);
        if (y != null) yearsInt.add(y);
      }

      return yearsInt;
    }
    return null;
  }

  @override
  Future<int> getDocsCount(int? year) async {
    Directory docsPath = Directory(
      dirPath(type: year != null ? "${PathType.docs.name}/$year" : PathType.docs.name),
    );

    if (docsPath.existsSync()) {
      List<FileSystemEntity> result = docsPath.listSync(recursive: true);
      return result.where((e) {
        return e is File && e.path.endsWith(AppConstant.documentExstension);
      }).length;
    }

    return 0;
  }
}
