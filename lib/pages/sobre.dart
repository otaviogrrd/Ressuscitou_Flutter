import 'package:flutter/material.dart';


class SobrePage extends StatefulWidget {
  @override
  _SobrePageState createState() => _SobrePageState();
}

class _SobrePageState extends State<SobrePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Ressuscitou')),
        body: Center(
          child: Padding(
              padding: EdgeInsets.all(26.0),
              child: Column(children: <Widget>[
                Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ultrices sagittis orci a scelerisque purus semper eget. Platea dictumst vestibulum rhoncus est pellentesque. Pellentesque eu tincidunt tortor aliquam nulla facilisi cras. Suspendisse ultrices gravida dictum fusce. Laoreet id donec ultrices tincidunt arcu non sodales neque sodales. Sed velit dignissim sodales ut eu. Vitae sapien pellentesque habitant morbi. Fermentum iaculis eu non diam phasellus vestibulum lorem sed. Purus non enim praesent elementum facilisis leo vel fringilla est. Ultrices sagittis orci a scelerisque purus. Volutpat diam ut venenatis tellus in metus vulputate.',
                    textAlign: TextAlign.center),
                Text(
                    'Nisl condimentum id venenatis a condimentum vitae sapien pellentesque habitant. Ac orci phasellus egestas tellus rutrum. Facilisis leo vel fringilla est.',
                    textAlign: TextAlign.center)
              ])),
        ));
  }
}
