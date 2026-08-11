import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart' show kIsCupertino;
import 'package:storypad/core/objects/nextcloud_user_object.dart';
import 'package:storypad/core/services/backups/nextcloud_folder_name_validator.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpConnectNextcloudSheet extends BaseBottomSheet {
  const SpConnectNextcloudSheet({
    this.initialServerUrl,
    this.initialUsername,
    this.initialFolderName,
  });

  /// When set (a reconnect after the stored app password stopped working),
  /// the server URL and username are pre-filled and read-only-flavored copy
  /// is shown — only a new app password is asked for.
  final String? initialServerUrl;
  final String? initialUsername;

  /// The account's existing storage folder, carried through silently on
  /// reconnect (no field shown for it) so re-submitting doesn't reset it back
  /// to the default — changing where data is stored isn't what "reconnect"
  /// is for.
  final String? initialFolderName;

  bool get isReconnect => initialServerUrl != null || initialUsername != null;

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return _ConnectNextcloudForm(
      bottomPadding: bottomPadding,
      initialServerUrl: initialServerUrl,
      initialUsername: initialUsername,
      initialFolderName: initialFolderName,
      isReconnect: isReconnect,
    );
  }
}

class _ConnectNextcloudForm extends StatefulWidget {
  const _ConnectNextcloudForm({
    required this.bottomPadding,
    required this.initialServerUrl,
    required this.initialUsername,
    required this.initialFolderName,
    required this.isReconnect,
  });

  final double bottomPadding;
  final String? initialServerUrl;
  final String? initialUsername;
  final String? initialFolderName;
  final bool isReconnect;

  @override
  State<_ConnectNextcloudForm> createState() => _ConnectNextcloudFormState();
}

class _ConnectNextcloudFormState extends State<_ConnectNextcloudForm> {
  final _formKey = GlobalKey<FormState>();
  late final _serverUrlController = TextEditingController(text: widget.initialServerUrl);
  late final _usernameController = TextEditingController(text: widget.initialUsername);
  final _appPasswordController = TextEditingController();
  late final _folderNameController = TextEditingController(
    text: widget.initialFolderName ?? NextcloudUserObject.defaultFolderName,
  );

  bool _connecting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _appPasswordController.dispose();
    _folderNameController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return tr("general.required");
    return null;
  }

  Future<void> _connect() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _connecting = true;
      _errorMessage = null;
    });

    final success = await context.read<BackupProvider>().connectNextcloud(
      context,
      serverUrl: _serverUrlController.text.trim(),
      username: _usernameController.text.trim(),
      appPassword: _appPasswordController.text,
      folderName: widget.isReconnect ? widget.initialFolderName : _folderNameController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _connecting = false;
        _errorMessage = tr("dialog.connect_nextcloud.failed");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 12.0,
          children: [
            Text(
              tr(widget.isReconnect ? "dialog.connect_nextcloud.reconnect_title" : "dialog.connect_nextcloud.title"),
              style: TextTheme.of(context).titleLarge?.copyWith(color: ColorScheme.of(context).primary),
            ),
            Text(
              tr(
                widget.isReconnect ? "dialog.connect_nextcloud.reconnect_message" : "dialog.connect_nextcloud.message",
              ),
              style: TextTheme.of(context).bodyLarge,
            ),
            _buildField(
              controller: _serverUrlController,
              hint: tr("input.nextcloud_server_url.hint"),
              keyboardType: TextInputType.url,
              // Reconnect only replaces the app password for the same
              // account — editing the server/username here would silently
              // switch to a different account through connect() without any
              // of the sign-out cleanup that normally goes with that (stale
              // folder/auto-backup preference/import history would all
              // carry over from the old account).
              enabled: !widget.isReconnect,
            ),
            _buildField(
              controller: _usernameController,
              hint: tr("input.nextcloud_username.hint"),
              keyboardType: TextInputType.text,
              enabled: !widget.isReconnect,
            ),
            _buildField(
              controller: _appPasswordController,
              hint: tr("input.nextcloud_app_password.hint"),
              obscureText: true,
              autofocus: widget.isReconnect,
            ),
            if (!widget.isReconnect) _buildFolderNameField(context),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextTheme.of(context).bodySmall?.copyWith(color: ColorScheme.of(context).error),
              ),
            const SizedBox(height: 4.0),
            SizedBox(width: double.infinity, child: _buildConnectButton(context)),
            SizedBox(height: widget.bottomPadding),
          ],
        ),
      ),
    );
  }

  /// Distinct from [_buildField]: pre-filled with the default rather than
  /// empty, optional-but-validated (blank falls back to the default, but
  /// bad characters are rejected — see [NextcloudFolderNameValidator]), and
  /// shows a live path preview beneath it so the user always knows where
  /// their data will land as they type.
  Widget _buildFolderNameField(BuildContext context) {
    final hint = tr("input.nextcloud_folder_name.hint");

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _folderNameController,
      builder: (context, value, _) {
        final trimmed = value.text.trim();
        final validationError = NextcloudFolderNameValidator.validate(trimmed);
        final helperText = validationError == null
            ? tr(
                "input.nextcloud_folder_name.helper",
                namedArgs: {'SP_PATH': trimmed.isEmpty ? NextcloudUserObject.defaultFolderName : trimmed},
              )
            : _folderNameErrorMessage(validationError);

        if (kIsCupertino) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4.0,
            children: [
              FormField<String>(
                initialValue: _folderNameController.text,
                validator: _folderNameValidator,
                builder: (state) => CupertinoTextField(
                  controller: _folderNameController,
                  placeholder: hint,
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  onChanged: (v) => state.didChange(v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  helperText,
                  style: TextTheme.of(context).bodySmall?.copyWith(
                    color: validationError == null ? ColorScheme.of(context).outline : ColorScheme.of(context).error,
                  ),
                ),
              ),
            ],
          );
        }

        return TextFormField(
          controller: _folderNameController,
          keyboardType: TextInputType.text,
          autocorrect: false,
          validator: _folderNameValidator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(hintText: hint, helperText: helperText, helperMaxLines: 2),
        );
      },
    );
  }

  String? _folderNameValidator(String? value) {
    final error = NextcloudFolderNameValidator.validate(value?.trim());
    return error == null ? null : _folderNameErrorMessage(error);
  }

  String _folderNameErrorMessage(NextcloudFolderNameValidationError error) {
    switch (error) {
      case NextcloudFolderNameValidationError.invalidCharacters:
        return tr("input.nextcloud_folder_name.error_invalid_characters");
      case NextcloudFolderNameValidationError.segmentTooLong:
        return tr("input.nextcloud_folder_name.error_too_long");
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool autofocus = false,
    bool enabled = true,
  }) {
    if (kIsCupertino) {
      return FormField<String>(
        // Without this, a pre-filled field (reconnect mode) the user never
        // types into stays null internally, so validate() rejects it as
        // empty even though the CupertinoTextField clearly shows text —
        // _connect() then returns silently before ever setting _connecting.
        initialValue: controller.text,
        validator: _requiredValidator,
        builder: (state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4.0,
            children: [
              CupertinoTextField(
                controller: controller,
                placeholder: hint,
                keyboardType: keyboardType,
                obscureText: obscureText,
                autocorrect: false,
                autofocus: autofocus,
                enabled: enabled,
                onChanged: (value) => state.didChange(value),
              ),
              // Material's TextFormField shows this via its own decoration
              // automatically — Cupertino has no equivalent, so without this
              // a failed validation (e.g. tapping Connect with an empty
              // field) blocks submission with zero visible feedback.
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    state.errorText!,
                    style: TextTheme.of(context).bodySmall?.copyWith(color: ColorScheme.of(context).error),
                  ),
                ),
            ],
          );
        },
      );
    }

    return TextFormField(
      controller: controller,
      validator: _requiredValidator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: false,
      autofocus: autofocus,
      enabled: enabled,
      decoration: InputDecoration(hintText: hint),
    );
  }

  Widget _buildConnectButton(BuildContext context) {
    if (kIsCupertino) {
      return CupertinoButton.filled(
        sizeStyle: CupertinoButtonSize.medium,
        onPressed: _connecting ? null : _connect,
        child: _connecting
            ? const CupertinoActivityIndicator()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                spacing: 8.0,
                children: [
                  const Icon(SpIcons.nextcloud),
                  Text(tr(widget.isReconnect ? "button.reconnect" : "button.connect")),
                ],
              ),
      );
    }

    return FilledButton.icon(
      icon: _connecting
          ? const SizedBox.square(dimension: 16.0, child: CircularProgressIndicator.adaptive())
          : const Icon(SpIcons.nextcloud),
      label: Text(tr(widget.isReconnect ? "button.reconnect" : "button.connect")),
      onPressed: _connecting ? null : _connect,
    );
  }
}
