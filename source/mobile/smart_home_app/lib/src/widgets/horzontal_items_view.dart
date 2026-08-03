import 'package:flutter/material.dart';

class HorizontalItemsView<T> extends StatelessWidget {
  const HorizontalItemsView(
      {Key? key,
      required this.itemBuilder,
      this.size,
      this.items = const [],
      this.paddingItem,
      this.mainAxisAlignment = MainAxisAlignment.start})
      : super(key: key);

  final List<T> items;
  final double? size;
  final MainAxisAlignment mainAxisAlignment;
  final double? paddingItem;
  final Widget Function(T item, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: mainAxisAlignment,
        children: List.generate(
            items.length,
            (index) => size != null
                ? Padding(
                    padding: EdgeInsets.only(
                        left: index == 0 ? 0 : (paddingItem ?? 6),
                        right: index < items.length
                            ? (paddingItem ?? 6)
                            : (paddingItem ?? 6)),
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: itemBuilder(items[index], index),
                    ),
                  )
                : Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: index == 0 ? 0 : (paddingItem ?? 6),
                          right: index < items.length
                              ? (paddingItem ?? 6)
                              : (paddingItem ?? 6)),
                      child: itemBuilder(items[index], index),
                    ),
                  )));
  }
}
