import 'package:flutter/material.dart';

import 'package:discuzq/widgets/ui/ui.dart';

class DiscuzIcon extends StatelessWidget {
  final double size;
  final dynamic icon;
  final Color color;
  final bool withOpacity;

  const DiscuzIcon(this.icon,
      {Key key, this.size = 24, this.color, this.withOpacity = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon.runtimeType == int ? IconData(icon, fontFamily: 'iconfont') : icon,
      size: size,
      color: _iconColor(context),
    );
  }

  Color _iconColor(BuildContext context){
    final Color iconColor = color ?? DiscuzApp.themeOf(context).primaryColor;
    if(withOpacity){
      return iconColor.withOpacity(.73);
    }
    return iconColor;
  }
}
