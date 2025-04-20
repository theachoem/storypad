import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/relax_sound_object.dart';

void main() async {
  group("RelaxSoundObject.defaultSounds", () {
    test('it make sure every translation, svg & music path is valid', () async {
      for (final sounds in RelaxSoundObject.defaultSounds().values) {
        for (final sound in sounds) {
          bool soundFileExist = File("firestore_storages/${sound.svgIconUrlPath}").existsSync();
          bool iconFileExist = File("firestore_storages/${sound.svgIconUrlPath}").existsSync();
          bool translationExist = trExists(sound.translationKey);

          debugPrint('${sound.soundUrlPath} | ${sound.svgIconUrlPath}');

          expect(soundFileExist, true);
          expect(iconFileExist, true);
          expect(translationExist, true);
        }
      }
    });
  });
}
