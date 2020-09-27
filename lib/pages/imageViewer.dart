import "package:flutter/material.dart";
import "package:photo_view/photo_view.dart";

class ImageViwerPage extends StatefulWidget {
  final String img;
  final String title;

  ImageViwerPage({Key key, @required this.img, @required this.title}) : super(key: key);

  @override
  _ImageViwerPageState createState() => new _ImageViwerPageState();
}

class _ImageViwerPageState extends State<ImageViwerPage> {
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.title),centerTitle: false),
        body: PhotoView(
          backgroundDecoration: BoxDecoration(color: Colors.black26),
          imageProvider: AssetImage(widget.img),
        ));
  }
}
