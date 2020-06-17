import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:ressuscitou/model/canto.dart';
import 'dart:convert';

class CantoPage extends StatefulWidget {
  final Canto canto;

  CantoPage({Key key, @required this.canto}) : super(key: key);

  @override
  _CantoPageState createState() => _CantoPageState();
}

class _CantoPageState extends State<CantoPage> {
  @override
  Widget build(BuildContext context) {
    var str = utf8.decode(base64.decode(widget.canto.extBase64));
    return WebviewScaffold(
      appBar: AppBar(
        title: Text('Ressuscitou'),
      ),
      url: Uri.dataFromString(str, mimeType: 'text/html', encoding: Encoding.getByName('utf-8')).toString(),
      withZoom: true,
      hidden: true,
    );
  }
}
