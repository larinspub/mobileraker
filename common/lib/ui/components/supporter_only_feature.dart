/*
 * Copyright (c) 2023. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:go_router/go_router.dart';

class SupporterOnlyFeature extends StatelessWidget {
  const SupporterOnlyFeature({
    Key? key,
    required this.text, this.header}) : super(key: key);

  final Widget text;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        header ??
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: const Icon(
                FlutterIcons.hand_holding_heart_faw5s,
                size: 32,
              ),
            ),
        DefaultTextStyle(textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall!, child: text),
        TextButton(
            onPressed: () {
              context.pushNamed('supportDev');
            },
            child: const Text('components.supporter_only_feature.button').tr())
      ],
    );
  }
}
