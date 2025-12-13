import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/objects/web_dev_user_object.dart';
import 'package:storypad/views/home/home_view.dart';

class WebDavCredentialsInputterService {
  Future<WebDevUserObject?> open() async {
    if (HomeView.homeContext == null) return null;

    final result = await showTextInputDialog(
      context: HomeView.homeContext!,
      title: 'Enter your WebDAV server URL & password',
      message: '''Make sure the user "storypad" has read & write access to:
{Server URL}/webdav/StoryPad''',
      textFields: [
        DialogTextField(
          hintText: 'eg. http://localhost',
          keyboardType: TextInputType.url,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the server URL';
            }
            return null;
          },
        ),
        DialogTextField(
          hintText: 'Password',
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the password';
            }
            return null;
          },
        ),
      ],
    );

    if (result == null || result.length < 3) {
      return null;
    }

    return WebDevUserObject(
      serverUrl: result[0],
      password: result[2],
    );
  }
}
