/*
 * Copyright (c) 2023. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/service/ui/dialog_service_interface.dart';
import 'package:common/util/extensions/double_extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobileraker/service/ui/dialog_service_impl.dart';

final initialFormType = Provider.autoDispose<DialogIdentifierMixin>(
  (ref) => throw UnimplementedError(),
);

final numFraction = Provider.autoDispose<int>((ref) => throw UnimplementedError());

final dialogCompleter = Provider.autoDispose<DialogCompleter>(name: 'dialogCompleter', (ref) {
  throw UnimplementedError();
});

class NumberEditDialogArguments {
  final num min;
  final num? max;
  final num current;
  final int fraction;

  const NumberEditDialogArguments({
    this.min = 0,
    this.max,
    required this.current,
    this.fraction = 0,
  });

  NumberEditDialogArguments copyWith({
    num? min,
    num? max = double.nan,
    num? current,
    int? fraction,
  }) {
    return NumberEditDialogArguments(
      current: current ?? this.current,
      min: min ?? this.min,
      max: (max?.isNaN ?? false) ? this.max : max,
      fraction: fraction ?? this.fraction,
    );
  }
}

final numEditFormKeyProvider = Provider.autoDispose<GlobalKey<FormBuilderState>>(
  (ref) => GlobalKey<FormBuilderState>(),
);

final numEditFormDialogController =
    StateNotifierProvider.autoDispose<NumEditFormDialogController, DialogIdentifierMixin>(
        (ref) => NumEditFormDialogController(ref));

class NumEditFormDialogController extends StateNotifier<DialogIdentifierMixin> {
  NumEditFormDialogController(this.ref) : super(ref.read(initialFormType));

  final AutoDisposeRef ref;

  FormBuilderState get _formBuilderState => ref.read(numEditFormKeyProvider).currentState!;

  onFormConfirm() {
    if (!_formBuilderState.saveAndValidate()) return;

    double val;
    if (state == DialogType.numEdit) {
      num cur = _formBuilderState.value['textValue'];
      val = cur.toDouble();
    } else {
      double cur = _formBuilderState.value['rangeValue'];
      val = cur;
    }
    ref.read(dialogCompleter)(DialogResponse(
      confirmed: true,
      data: val.toPrecision(ref.read(numFraction)),
    ));
  }

  onFormDecline() {
    ref.read(dialogCompleter)(DialogResponse.aborted());
  }

  switchToOtherVariant() {
    DialogType targetVariant;
    _formBuilderState.save();
    if (state == DialogType.numEdit) {
      targetVariant = DialogType.rangeEdit;

      num cur = _formBuilderState.value['textValue'];
      _formBuilderState.fields['rangeValue']!.didChange(cur.toDouble());
    } else {
      targetVariant = DialogType.numEdit;
      double cur = _formBuilderState.value['rangeValue'];
      _formBuilderState.fields['textValue']!.didChange(cur.toStringAsFixed(ref.read(numFraction)));
    }
    state = targetVariant;
  }
}
