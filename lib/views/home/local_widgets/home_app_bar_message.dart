part of '../home_view.dart';

class _HomeAppBarMessage extends StatelessWidget {
  const _HomeAppBarMessage();

  @override
  Widget build(BuildContext context) {
    return Consumer<BackupProvider>(
      child: _Typewriter(
        WelcomeMessageService.get(context),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextTheme.of(context).bodyLarge,
      ),
      builder: (context, provider, child) {
        String? title;
        Widget? trailing;

        bool showWelcomeMessage = true;

        if (provider.syncing) {
          showWelcomeMessage = false;
          title = "${tr("page.home.app_bar.messages.we_syncing_ur_data")} ";
          trailing = Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: const SizedBox.square(
              dimension: 12.0,
              child: CircularProgressIndicator.adaptive(),
            ),
          );
        } else {
          // title = "${tr("page.home.app_bar.messages.ready_to_syn_data")} ";
          // trailing = Container(
          //   margin: const EdgeInsets.symmetric(horizontal: 4.0),
          //   child: const Icon(
          //     Icons.cloud_off,
          //     size: 16.0,
          //   ),
          // );
          showWelcomeMessage = true;
          title = null;
          trailing = null;
        }

        return SpCrossFade(
          duration: Durations.medium3,
          alignment: Alignment.topLeft,
          showFirst: showWelcomeMessage,
          firstChild: child!,
          secondChild: RichText(
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textScaler: MediaQuery.textScalerOf(context),
            text: TextSpan(
              style: TextTheme.of(context).bodyLarge,
              text: title,
              children: trailing == null ? null : [WidgetSpan(alignment: PlaceholderAlignment.middle, child: trailing)],
            ),
          ),
        );
      },
    );
  }
}

class _Typewriter extends StatefulWidget {
  const _Typewriter(
    this.text, {
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.style,
  });

  final String text;
  final int? maxLines;
  final TextOverflow overflow;
  final TextStyle? style;

  @override
  State<_Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<_Typewriter> {
  String currentText = '';

  @override
  void didUpdateWidget(covariant _Typewriter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text) {
      currentText = '';
      start();
    }
  }

  @override
  void initState() {
    super.initState();
    start();
  }

  Future<void> start() async {
    while (widget.text != currentText) {
      currentText += widget.text[currentText.length];
      setState(() {});
      await Future.delayed(Duration(milliseconds: 150));
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayText = currentText;

    if (currentText != widget.text) {
      displayText = "$displayText ▌";
    }

    return Text(
      displayText,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      style: widget.style,
    );
  }
}
