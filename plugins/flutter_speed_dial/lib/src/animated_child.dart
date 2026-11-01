import 'package:flutter/material.dart';

class AnimatedChild extends AnimatedWidget {
  final int index;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final Widget? child;

  final String? label;
  final TextStyle? labelStyle;
  final Color? labelBackgroundColor;
  final Widget? labelWidget;

  final bool visible;
  final VoidCallback? onTap;
  final VoidCallback toggleChildren;
  final ShapeBorder? shape;
  final String? heroTag;

  AnimatedChild({
    Key? key,
    required Animation<double> animation,
    required this.index,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 4.0,
    this.child,
    this.label,
    this.labelStyle,
    this.labelBackgroundColor,
    this.labelWidget,
    this.visible = false,
    this.onTap,
    required this.toggleChildren,
    this.shape,
    this.heroTag,
  }) : super(key: key, listenable: animation);

  Widget buildLabel() {
    final animation = listenable as Animation<double>;

    if (!((label != null || labelWidget != null) && visible && animation.value == 60.0)) {
      return Container();
    }

    if (labelWidget != null) return labelWidget!;

    return GestureDetector(
      onTap: _performAction,
      child: Container(
        //padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
        margin: EdgeInsets.only(right: 8.0),
        decoration: BoxDecoration(
          color: labelBackgroundColor ?? Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(6.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.7),
              offset: Offset(0.8, 0.8),
              blurRadius: 2.4,
            )
          ],
        ),
        child: Text(label ?? "", style: labelStyle),
      ),
    );
  }

  void _performAction() {
    onTap?.call();
    toggleChildren();
  }

  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;

    final Widget buttonChild = animation.value > 50.0
        ? Container(
            width: animation.value,
            height: animation.value,
            child: child ?? Container(),
          )
        : Container(
            width: 0.0,
            height: 0.0,
          );

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          buildLabel(),
          Container(
            width: 60.0,
            height: animation.value,
            padding: EdgeInsets.only(bottom: 60.0 - animation.value),
            child: Container(
              height: 60.0,
              width: animation.value,
              padding: EdgeInsets.only(bottom: 6),
              child: FloatingActionButton(
                heroTag: heroTag,
                onPressed: _performAction,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                elevation: elevation,
                child: buttonChild,
              ),
            ),
          )
        ],
      ),
    );
  }
}
