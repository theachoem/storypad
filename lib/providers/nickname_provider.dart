import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/widgets/bottom_sheets/sp_nickname_bottom_sheet.dart';

class NicknameProvider extends ChangeNotifier {
  String? nickname = PreferenceDbModel.db.nickname.get();

  void changeName(BuildContext context) async {
    final result = await SpNicknameBottomSheet(nickname: nickname).show(context: context);

    if (result is String) {
      setNickname(result);
    }
  }

  void setNickname(String nickname) {
    if (nickname == this.nickname) return;

    PreferenceDbModel.db.nickname.set(nickname);
    this.nickname = PreferenceDbModel.db.nickname.get();
    notifyListeners();
  }
}
