import 'package:flutter/material.dart';

/// Виджет-контейнер для ограничения максимальной ширины содержимого.
/// Предотвращает растягивание интерфейса на весь экран на широких десктопных мониторах.
class ResponsiveContentContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveContentContainer({
    super.key,
    required this.child,
    this.maxWidth = 620.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
