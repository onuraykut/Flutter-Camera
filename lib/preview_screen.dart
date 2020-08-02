import 'dart:io';
import 'dart:typed_data';

import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreviewScreen extends StatefulWidget{

  final String imgPath;



  PreviewScreen({this.imgPath});

  @override
  _PreviewScreenState createState() => _PreviewScreenState();



}
class _PreviewScreenState extends State<PreviewScreen>{

  SharedPreferences lastPicturePath ;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() => lastPicturePath = prefs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: PhotoView(imageProvider: FileImage(File(widget.imgPath),),)
              //Image.file(File(widget.imgPath),fit: BoxFit.contain,),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: 60.0,
                color: Colors.black,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.delete,color: Colors.white,),
                        onPressed: (){
                          File file = new File(widget.imgPath);
                          file.delete();
                          lastPicturePath.setString("path", null);
                          Navigator.pop(context);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.share,color: Colors.white,),
                        onPressed: (){
                          getBytesFromFile().then((bytes){
                            Share.file('Share via', basename(widget.imgPath), bytes.buffer.asUint8List(),'image/path');
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<ByteData> getBytesFromFile() async{
    Uint8List bytes = File(widget.imgPath).readAsBytesSync() as Uint8List;
    return ByteData.view(bytes.buffer);
  }
}