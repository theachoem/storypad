import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/add_on_object.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'add_ons_view.dart';

class AddOnsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final AddOnsRoute params;

  AddOnsViewModel({
    required this.params,
  });

  List<AddOnObject> get addOns => [
        AddOnObject(
          title: tr('add_ons.relax_sounds.title'),
          subtitle: tr('add_ons.relax_sounds.subtitle'),
          displayPrice: '0.99\$',
          iconData: SpIcons.musicNote,
          weekdayColor: 1,
          demoImages: [
            'https://storypad.me/usecases/morning_intention.jpg',
            'https://storypad.me/usecases/thought.jpg',
            'https://storypad.me/usecases/mood_tracker.jpg',
          ],
        ),
        AddOnObject(
          title: tr('add_ons.templates.title'),
          subtitle: tr('add_ons.templates.subtitle'),
          displayPrice: '0.99\$',
          iconData: SpIcons.lightBulb,
          weekdayColor: 2,
          demoImages: [
            'https://storypad.me/usecases/morning_intention.jpg',
            'https://storypad.me/usecases/thought.jpg',
          ],
        ),
      ];
}
