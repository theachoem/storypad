part of 'new_year_view.dart';

class _NewYearContent extends StatelessWidget {
  const _NewYearContent(this.viewModel);

  final NewYearViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SpTextInputsPage(
      appBar: AppBar(title: Text(tr("page.add_year.title"))),
      fields: [
        SpTextInputField(
          hintText: tr("input.year.hint"),
          keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
          validator: (value) {
            int? year = int.tryParse(value ?? '');

            if (year == null) return tr("input.message.invalid");
            if (year > DateTime.now().year + 1000) return tr("input.message.invalid");
            if (viewModel.params.years?.keys.contains(year) == true) return tr("input.message.already_exist");

            return null;
          },
        ),
      ],
    );
  }
}
