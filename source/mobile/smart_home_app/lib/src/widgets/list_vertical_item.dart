import 'package:flutter/material.dart';
import 'package:smart_home_app/src/config/responsive.dart';

class ListVerticalItem<T> extends StatelessWidget {
  const ListVerticalItem({
    required this.itemBuilder,
    Key? key,
    this.items = const [],
    this.lineItemCount = 2,
    this.paddingBetweenItem = 8,
    this.paddingBetweenLine = 4,
    this.controller,
    this.divider,
  }) : super(key: key);

  final List<T> items;
  final Widget Function(int index, T item) itemBuilder;
  final double paddingBetweenItem;
  final double paddingBetweenLine;
  final int lineItemCount;
  final Widget? divider;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final itemColumn = items.length ~/ lineItemCount + 1;
    Widget widget;
    widget = ListView.separated(
        shrinkWrap: true,
        padding: setPadding(),
        controller: controller,
        itemBuilder: (context, index) => buildLineItem(index),
        separatorBuilder: (context, index) => divider ?? SizedBox(),
        itemCount: itemColumn);
    return widget;
  }

  Widget buildLineItem(int index) {
    final currentIndex = index * lineItemCount;
    if (currentIndex >= items.length) return const SizedBox();
    return Row(
      children: List.generate(
        lineItemCount,
        (index) => Expanded(
          child: Padding(
              padding: EdgeInsets.only(
                  left: index == 0 ? 0 : paddingBetweenItem,
                  right: index == 0 ? paddingBetweenItem : 0),
              child: currentIndex + index >= items.length
                  ? Container()
                  : itemBuilder(
                      currentIndex + index, items[currentIndex + index])),
        ),
      ),
    );
  }
}
