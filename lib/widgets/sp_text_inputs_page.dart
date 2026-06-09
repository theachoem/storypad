import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';

@immutable
class SpTextInputField {
  const SpTextInputField({
    this.initialText,
    this.hintText,
    this.labelText,
    this.maxLines,
    this.keyboardType,
    this.validator,
  });

  final String? initialText;
  final String? hintText;
  final String? labelText;
  final int? maxLines;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
}

class SpTextInputsPage extends StatefulWidget {
  const SpTextInputsPage({
    super.key,
    this.appBar,
    this.saveButtonLabel,
    required this.fields,
    this.contentOnly = false,
    this.header,
    this.onSubmitted,
  });

  final PreferredSizeWidget? appBar;
  final List<SpTextInputField> fields;
  final String? saveButtonLabel;
  final bool contentOnly;

  // Optional widget rendered above the input fields (e.g. a category chip selector).
  final Widget? header;

  // When provided, called with the trimmed field values on a valid submit instead of
  // popping the route with the values list. Lets callers return a custom result.
  final void Function(List<String> values)? onSubmitted;

  @override
  State<SpTextInputsPage> createState() => _SpTextInputsPageState();
}

class _SpTextInputsPageState extends State<SpTextInputsPage> {
  late final List<TextEditingController> controllers;

  @override
  void initState() {
    super.initState();

    controllers = widget.fields.map((field) {
      return TextEditingController(text: field.initialText);
    }).toList();
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Builder(
        builder: (context) {
          if (widget.contentOnly) {
            return buildContent(context);
          }

          return Scaffold(
            appBar: widget.appBar,
            body: buildContent(context),
          );
        },
      ),
    );
  }

  Widget buildContent(BuildContext context) {
    final screenPadding = MediaQuery.paddingOf(context);
    return ListView(
      padding: const EdgeInsets.all(
        16.0,
      ).add(EdgeInsets.only(left: screenPadding.left, right: screenPadding.right, bottom: screenPadding.bottom)),
      children: [
        if (widget.header != null) ...[
          widget.header!,
          const SizedBox(height: 16.0),
        ],
        for (int index = 0; index < controllers.length; index++) buildTextField(index, context),
        const SizedBox(height: 16.0),
        buildSaveButton(context),
      ],
    );
  }

  Widget buildSaveButton(BuildContext context) {
    if (kIsCupertino) {
      return CupertinoButton.filled(
        disabledColor: Theme.of(context).disabledColor,
        sizeStyle: CupertinoButtonSize.medium,
        child: Text(widget.saveButtonLabel ?? tr("button.save")),
        onPressed: () => submit(context),
      );
    } else {
      return FilledButton.icon(
        label: Text(widget.saveButtonLabel ?? tr("button.save")),
        onPressed: () => submit(context),
      );
    }
  }

  Widget buildTextField(int index, BuildContext context) {
    bool lastIndex = index == controllers.length - 1;
    Widget? textField;

    if (kIsCupertino) {
      textField = FormField(
        validator: widget.fields[index].validator,
        builder: (state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4.0,
            children: [
              CupertinoTextField(
                autofocus: index == 0,
                maxLines: widget.fields[index].maxLines,
                textInputAction: lastIndex ? TextInputAction.done : TextInputAction.next,
                controller: controllers[index],
                keyboardType: widget.fields[index].keyboardType,
                placeholder: widget.fields[index].hintText,
                onSubmitted: (text) => submit(context),
                onChanged: (value) => state.didChange(value),
              ),
              if (state.errorText != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    state.errorText!,
                    style: TextTheme.of(context).bodyMedium?.copyWith(color: ColorScheme.of(context).error),
                  ),
                ),
            ],
          );
        },
      );
    } else {
      textField = TextFormField(
        autofocus: index == 0,
        textInputAction: lastIndex ? TextInputAction.done : TextInputAction.next,
        controller: controllers[index],
        keyboardType: widget.fields[index].keyboardType,
        decoration: InputDecoration(
          hintText: widget.fields[index].hintText,
          labelText: widget.fields[index].labelText,
        ),
        validator: widget.fields[index].validator,
        onFieldSubmitted: (text) => submit(context),
      );
    }

    return Container(
      margin: lastIndex ? null : const EdgeInsets.only(bottom: 16.0),
      child: textField,
    );
  }

  void submit(BuildContext context) {
    if (!Form.of(context).validate()) return;
    final values = controllers.map((e) => e.text.trim()).toList();
    if (widget.onSubmitted != null) {
      widget.onSubmitted!(values);
    } else {
      Navigator.of(context).pop(values);
    }
  }
}
