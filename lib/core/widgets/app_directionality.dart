import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AppDirectionality extends StatelessWidget {
  final Widget child;

  const AppDirectionality({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode;
    final isRtl = currentLocale == 'ar' || currentLocale == 'he';

    return Container(
      alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
      child: DefaultTextStyle(
        style: DefaultTextStyle.of(context).style,
        textAlign: isRtl ? TextAlign.right : TextAlign.left,
        child: child,
      ),
    );
  }
}
