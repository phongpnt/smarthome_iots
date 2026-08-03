import 'package:smart_home_app/src/widgets/text_field/custom_text_field_model.dart';

class TextFormModel {
  final List<CustomTextFieldModel> models;
  final void Function() onSubmit;

  TextFormModel({required this.models, required this.onSubmit});

  void dispose() {
    for (final model in models) {
      model.dispose();
    }
  }

  void validate() {
    var isValid = true;
    for (final model in models) {
      final validateField = model.onValidate();
      if (!validateField) {
        if (isValid == true) {
          isValid = false;
        }
      }
    }
    if (isValid) {
      onSubmit();
    }
  }
}
