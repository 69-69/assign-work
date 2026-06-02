import 'package:flutter/material.dart';

class FormGroupCardModel {
  const FormGroupCardModel({
    required this.title,
    required this.builder,
    this.contentPadding,
    this.subTitle='',
    this.isExpanded = false,
  });

  final String title;
  final String subTitle;
  final List<Widget> Function() builder;
  final EdgeInsets? contentPadding;
  final bool isExpanded;
}