import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State with SingleTickerProviderStateMixin {
  CameraController controller;
  List cameras;
  int selectedCameraIndex;
  String imgPath;
  String folderInAppDocDir;
  Animation transformation;
  AnimationController animationController;
  Tween<double> _translateValues = Tween<double>(begin: -55, end: 5);

  int selectedIndex = 0;
  bool isCaptured = false;

  List<String> photoMainCategory = [
    "Family",
    "Work",
    "Travel",
    "Private",
    "Add",
  ];

  @override
  void initState() {
    animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 5000),
        lowerBound: -55,
        upperBound: 5);
    animationController.forward();
    animationController.addListener(() {
      setState(() {});
    });

    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;

      if (cameras.length > 0) {
        setState(() {
          selectedCameraIndex = 0;
        });
        _initCameraController(cameras[selectedCameraIndex]).then((void v) {});
      } else {
        print('No camera available');
      }
    }).catchError((err) {
      print('Error :${err.code}Error message : ${err.message}');
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  Future _initCameraController(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(cameraDescription, ResolutionPreset.high);

    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (controller.value.hasError) {
        print('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    String defaultPathName = "Aile";
    double leftForIcon = 5;
    double leftForList = -55;
    bool menu = false;

    //Directory selectedPath = Directory(callFileMethod(defaultPathName));

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: _cameraPreviewWidget(),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 250),
                      height: height * 0.18,
                      width: double.infinity,
                      padding: EdgeInsets.all(15),
                      color: isCaptured ? Colors.greenAccent : Colors.black,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          _cameraToggleRowWidget(),
                          _cameraControlWidget(context),
                          //_cameraPreviewWidget(),
                          _getPreviewPicture(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedBuilder(
            animation: animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(animationController.value + 50, 0),
                child: child,
              );
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                  onTap: () {
                    debugPrint("Eben");
                    setState(() {
                      animationController.reverse();
                    });
                  },
                  child: Icon(
                    menu == false
                        ? Icons.arrow_back_ios
                        : Icons.arrow_forward_ios,
                    color: Colors.white,
                  )),
            ),
          ),

          // Bölümlerin Seçildiği Kısım
          AnimatedBuilder(
            animation: animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(animationController.value, 0),
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: photoMainCategory.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          InkWell(
                            onTap: () {
                              callFileMethod(photoMainCategory[index]);
                              if (index == (photoMainCategory.length - 1)) {
                                _showDialog(context);
                              }
                              setState(() {
                                selectedIndex = index;
                              });
                              debugPrint(index.toString());
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: CircleAvatar(
                                backgroundColor: selectedIndex == index
                                    ? Colors.green
                                    : Colors.transparent,
                                child: Container(
                                  height: 75,
                                  width: 75,
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: AssetImage(
                                              "assets/images/${photoMainCategory[index]}.png"))),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            photoMainCategory[index],
                            style: TextStyle(
                                color: selectedIndex == index
                                    ? Colors.green
                                    : Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(
                            height: 10,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(context) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text(
            "Folder Name",
            textAlign: TextAlign.center,
          ),
          content: TextField(
            controller: TextEditingController(),
            decoration: InputDecoration(),
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Okey"),
              onPressed: () {
                setState(() {
                  photoMainCategory.insert(
                      photoMainCategory.length - 1, "diger");
                  selectedIndex = photoMainCategory.length - 1;
                });
                Navigator.of(context).pop();
                //Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        );
      },
    );
  }

  /// Display Camera preview.
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Loading',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: CameraPreview(controller),
    );
  }

  /// Display the control bar with buttons to take pictures
  Widget _cameraControlWidget(context) {
    return FloatingActionButton(
      child: Icon(
        Icons.camera,
        color: Colors.black,
      ),
      backgroundColor: Colors.white,
      onPressed: () {
        _onCapturePressed(context);
      },
    );
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  Widget _cameraToggleRowWidget() {
    if (cameras == null || cameras.isEmpty) {
      return Spacer();
    }
    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;

    return Align(
      alignment: Alignment.centerLeft,
      child: FlatButton.icon(
        onPressed: _onSwitchCamera,
        icon: Icon(
          _getCameraLensIcon(lensDirection),
          color: Colors.white,
          size: 24,
        ),
        label: Text(
          '${lensDirection.toString().substring(lensDirection.toString().indexOf('.') + 1).toUpperCase()}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  IconData _getCameraLensIcon(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.back:
        return CupertinoIcons.switch_camera;
      case CameraLensDirection.front:
        return CupertinoIcons.switch_camera_solid;
      case CameraLensDirection.external:
        return Icons.camera;
      default:
        return Icons.device_unknown;
    }
  }

  void _showCameraException(CameraException e) {
    String errorText = 'Error:${e.code}\nError message : ${e.description}';
    print(errorText);
  }

  void _onCapturePressed(context) async {
    try {
      final path = join(
          (await getExternalStorageDirectory()).path, '${DateTime.now()}.png');
      await controller.takePicture(path);
      debugPrint(getTemporaryDirectory().toString());

      /* Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PreviewScreen(
                  imgPath: path,
                )),
      );*/
    } catch (e) {
      _showCameraException(e);
    }
    setState(() {


    });
  }

  void _onSwitchCamera() {
    selectedCameraIndex =
        selectedCameraIndex < cameras.length - 1 ? selectedCameraIndex + 1 : 0;
    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    _initCameraController(selectedCamera);
  }

  //CreateFolderInAppDocDir
  callFileMethod(fileName) async {
    folderInAppDocDir =
        await AppUtil.createFolderInAppDocDir(fileName.toString());
  }

  _getPreviewPicture() {
    return Container(
      width: 75,
      height: 75,
      // TODO Önceki Resim Getirilecek
      /* decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage("") )
          ),*/
    );
  }
}

class AppUtil {
  static Future<String> createFolderInAppDocDir(String folderName) async {
    //Get this App Document Directory
    final Directory _appDocDir = await getExternalStorageDirectory();
    debugPrint(_appDocDir.toString());

    //App Document Directory + folder name
    final Directory _appDocDirFolder =
        Directory('${_appDocDir.path}/$folderName/');
    if (await _appDocDirFolder.exists()) {
      //if folder already exists return path
      return _appDocDirFolder.path;
    } else {
      //if folder not exists create folder and then return its path
      final Directory _appDocDirNewFolder =
          await _appDocDirFolder.create(recursive: true);
      debugPrint(_appDocDirNewFolder.toString());
      return _appDocDirNewFolder.path;
    }
  }
}

/*

InkWell(
                  onTap: (){
                    callFileMethod("Work");
                    setState(() {
                      defaultPathName = "Work";
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: CircleAvatar(
                      child: Container(
                        height: 75,
                        width: 75,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage("assets/images/is.png"))),
                      ),
                    ),
                  ),
                ),
                Text(
                  "Work",
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(
                  height: 10,
                ),
                InkWell(
                  onTap: (){},
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: CircleAvatar(
                      child: Container(
                        height: 75,
                        width: 75,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage("assets/images/yemek.ico"),
                                fit: BoxFit.fitWidth)),
                      ),
                    ),
                  ),
                ),
                Text(
                  "Food",
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(
                  height: 10,
                ),
                InkWell(
                  onTap: (){},
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: CircleAvatar(
                      child: Container(
                        height: 75,
                        width: 75,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage("assets/images/private.png"))),
                      ),
                    ),
                  ),
                ),
                Text(
                  "Private",
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(
                  height: 10,
                ),
                InkWell(
                  onTap: (){},
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: CircleAvatar(
                      child: Container(
                        height: 75,
                        width: 75,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage("assets/images/diger.png"))),
                      ),
                    ),
                  ),
                ),
                Text(
                  "Other",
                  style: TextStyle(color: Colors.white),
                ),

*/
