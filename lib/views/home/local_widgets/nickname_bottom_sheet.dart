import 'package:flutter/material.dart';
import 'package:storypad/widgets/sp_default_text_controller.dart';

class NicknameBottomSheet extends StatelessWidget {
  const NicknameBottomSheet({
    super.key,
    required this.nickname,
  });

  final String? nickname;

  @override
  Widget build(BuildContext context) {
    return SpDefaultTextController(
      initialText: nickname,
      withForm: true,
      builder: (context, controller) {
        Future<void> save() async {
          if (Form.of(context).validate()) {
            Navigator.maybePop(context, controller.text.trim());
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Hello",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextTheme.of(context).titleLarge?.copyWith(color: ColorScheme.of(context).primary),
              ),
              Text(
                "What should I call you?",
                overflow: TextOverflow.ellipsis,
                style: TextTheme.of(context).bodyLarge,
                maxLines: 2,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: controller,
                onFieldSubmitted: (value) => save(),
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "Required";
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'Your nickname...',
                ),
              ),
              const SizedBox(height: 8.0),
              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, value, child) {
                    bool unchanged = value.text.trim().isEmpty || value.text.trim() == nickname;
                    return FilledButton(
                      onPressed: unchanged ? null : () => save(),
                      child: nickname == null ? const Text("Save") : const Text("Update"),
                    );
                  },
                ),
              ),
              AnimatedContainer(
                curve: Curves.fastEaseInToSlowEaseOut,
                duration: Durations.long2,
                height: MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
              )
            ],
          ),
        );
      },
    );
  }
}
