import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutobs/flutobs.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
    Flutobs.initSDK("appKey", "appSecret", "endPoint");
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Flutobs.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: UploadPage(),
    );
  }
}

class UploadPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return UploadState();
  }
}

class UploadState extends State<UploadPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              Container(
                height: 100,
              ),
              CustomButton(
                label: "upload",
                onTap: () async {
                  showImagePicker();
                },
              ),
            ]),
          )
        ],
      ),
    );
  }

  void upload(String filePath) {
    Flutobs.upload(filePath, "bucketName", "fileName");
  }

  ///获取照片
  Future showImagePicker() async {
    return showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 180,
            child: Column(
              children: [
                ListTile(
                  title: Center(
                    child: Text("拍照"),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    PickedFile pickedFile = await ImagePicker()
                        .getImage(source: ImageSource.camera);
                    debugPrint(pickedFile.path);
                  },
                ),
                ListTile(
                  title: Center(
                    child: Text("相册"),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    PickedFile pickedFile = await ImagePicker()
                        .getImage(source: ImageSource.gallery);
                    debugPrint(pickedFile.path);
                    upload(pickedFile.path);
                  },
                ),
                ListTile(
                  title: Center(
                    child: Text("取消"),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                )
              ],
            ),
          );
        });
  }
}

class CustomButton extends StatelessWidget {
  CustomButton({this.label, this.onTap});

  final String label;
  final onTap;

  @override
  Widget build(BuildContext context) {
    return new RaisedButton(
        onPressed: onTap,
        child: new Text(
          label,
          textDirection: TextDirection.ltr,
        ));
  }
}
