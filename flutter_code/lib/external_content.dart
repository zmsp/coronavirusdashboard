import 'dart:html';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ExternalContent extends StatelessWidget {
  final String url;

  ExternalContent(this.url);

  @override
  Widget build(BuildContext context) {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      url,
      (int viewId) => IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..referrerPolicy = "no-referrer"
        ..allowFullscreen = false
        ..allowPaymentRequest = false,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Flexible(
          child: Container(
            color: const Color(0xFFf5f5f5),
            child: HtmlElementView(viewType: url),
          ),
        ),
      ],
    );
  }
}
