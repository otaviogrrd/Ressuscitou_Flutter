import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageViwerPage extends StatefulWidget {
  String img = "";

  ImageViwerPage({Key key, @required this.img}) : super(key: key);

  @override
  _ImageViwerPageState createState() => new _ImageViwerPageState();
}

class _ImageViwerPageState extends State<ImageViwerPage> {
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: PhotoView(
          backgroundDecoration: BoxDecoration(color: Colors.black26),
          imageProvider: AssetImage(widget.img),
        ));
  }
}
