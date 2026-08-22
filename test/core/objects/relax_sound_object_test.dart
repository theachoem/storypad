import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/relax_sound_object.dart';
import 'package:storypad/gen/storage_hash_map.dart';

void main() async {
  group("RelaxSoundObject.defaultSounds", () {
    test('it make sure every translation, svg & music path was actually published', () async {
      for (final sound in RelaxSoundObject.defaultSounds()) {
        bool soundFileExist = kStorageHashMap.containsKey(sound.soundUrlPath);
        bool iconFileExist = kStorageHashMap.containsKey(sound.svgIconUrlPath);
        bool translationExist = trExists(sound.translationKey);

        debugPrint('${sound.soundUrlPath} | ${sound.svgIconUrlPath}');

        expect(soundFileExist, true, reason: '${sound.soundUrlPath} missing from kStorageHashMap');
        expect(iconFileExist, true, reason: '${sound.svgIconUrlPath} missing from kStorageHashMap');
        expect(translationExist, true);
      }
    });
  });
}
