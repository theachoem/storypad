part of '../home_view.dart';

class _HomeEmpty extends StatelessWidget {
  const _HomeEmpty({
    required this.viewModel,
  });

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    String message = tr('page.home.empty_message', namedArgs: {
      "YEAR": viewModel.year.toString(),
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 200),
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + kToolbarHeight),
          child: RichText(
            textAlign: TextAlign.center,
            textScaler: MediaQuery.textScalerOf(context),
            text: TextSpan(
              style: TextTheme.of(context).bodyLarge,
              children: [
                TextSpan(text: message.split("{EDIT_BUTTON}").first),
                const WidgetSpan(
                  child: Icon(Icons.edit, size: 16.0),
                  alignment: PlaceholderAlignment.middle,
                ),
                TextSpan(text: message.split("{EDIT_BUTTON}").last),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
