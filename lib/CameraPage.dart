import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:camera/camera.dart';
import 'package:directory_picker/directory_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission/permission.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'preview_screen.dart';

enum MenuEnum { changeName, delete }

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with SingleTickerProviderStateMixin {

  Animation animation;
  AnimationController animationController;
  Duration myDuration = Duration(milliseconds: 500);

  CameraController controller;
  List cameras;
  int selectedCameraIndex;
  String imgPath;
  int selectedIndex = 0;
  bool isMenuOpen = true;
  TextEditingController klasorAdicontroller = new TextEditingController();
  Directory externalDirectory;
  bool isCaptured = false;
  SharedPreferences lastPicturePath ;
  double width;
  double height;
  List<String> photoMainCategory = new List<String>();
  List<String> photoMainCategoryDefault = [
    "Family",
    "Work",
    "Travel",
    "Private",
    "Add",
  ];
  Future<void> init() async {
    await getStorage();
  }
  @override
  void initState() {
    // TODO: implement initState

    animationController = AnimationController(
        vsync: this, duration: myDuration, lowerBound: -55, upperBound: 5);
    animationController.addListener(() {
      setState(() {});
    });
   init();

    animationController.forward();

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

    SharedPreferences.getInstance().then((prefs) {
      String folder1 = prefs.getString("folder1") ?? "Family";
      String folder2 = prefs.getString("folder2") ?? "Work";
      String folder3 = prefs.getString("folder3") ?? "Travel";
      String folder4 = prefs.getString("folder4") ?? "Private";
      String folder5 = prefs.getString("folder5") ?? "Add";

      String folder6 = prefs.getString("folder6");
      String folder7 = prefs.getString("folder7");

      photoMainCategory.add(folder1);
      photoMainCategory.add(folder2);
      photoMainCategory.add(folder3);
      photoMainCategory.add(folder4);
      if(folder6!=null)
      photoMainCategory.add(folder6);
      if(folder7!=null)
      photoMainCategory.add(folder7);
      photoMainCategory.add(folder5);


      setState(() => lastPicturePath = prefs);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose

    animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            
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
                    duration: Duration(milliseconds: 500),

                    height: height * 0.18,
                    width: double.infinity,
                    color: isCaptured ? Colors.lightGreenAccent : Colors.black,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        _cameraToggleRowWidget(),
                        _cameraControlWidget(context),
                        _getPreviewPicture(context),
                        //_cameraPreviewWidget(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedPositioned(
            left: isMenuOpen == true ? animationController.value : -155,
            top:  height * 0.1,
            right: 0,
            duration: myDuration,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: photoMainCategory.length,
              itemBuilder: (BuildContext context, int index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    InkWell(
                      onTap: () {

                        if (index == (photoMainCategory.length - 1) && photoMainCategory.length<7) {
                          _showDialog(context);
                        }
                        if (index != (photoMainCategory.length-1))
                        setState(() {
                          selectedIndex = index;
                        });
                        debugPrint(index.toString());
                      },
                      onLongPress: (){
                        setState(() {
                          selectedIndex = index;
                        });
                        AwesomeDialog(
                            context: context,
                            animType: AnimType.SCALE,
                            headerAnimationLoop: true,
                            dialogType: DialogType.INFO,
                            title: 'What do you want to do?',
                            desc: "",
                            btnOkOnPress: () {
                              _changeFolderName(context);
                            },
                            btnCancelOnPress: () {},
                            btnOkIcon: Icons.folder_open,
                            btnOkColor: Colors.teal,
                            btnOkText: "Change folder name",
                            btnCancelIcon: Icons.delete,
                            btnCancelText: "Delete folder",
                            btnCancelColor: Colors.green,
                            onDissmissCallback: () {
                              deleteCustomFolder();
                            })..show();
//                        popUp(context);


                      },

                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: CircleAvatar(
                          backgroundColor: selectedIndex == index
                              ? Colors.greenAccent
                              : Colors.transparent,
                          child: Container(
                            height: 75,
                            width: 75,
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: AssetImage(
                                        "assets/images/${!photoMainCategoryDefault.contains(photoMainCategory[index]) ? "Camera" : photoMainCategory[index]}.png"))),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      photoMainCategory[index],
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                  ],
                );
              },
            ),
          ),
          AnimatedPositioned(
            duration: myDuration,
            left: isMenuOpen == true ?  width*0.13 : 0,
            top: height/2,
            child: InkWell(
              onTap: () {
                setState((){
                  if (isMenuOpen) animationController.reverse();
                  else animationController.forward();
                  isMenuOpen = !isMenuOpen;
                });
              },
              child: Icon(Icons.arrow_forward_ios,color: Colors.white,),
            ),
          ),
        ],
      ),
    );
  }
  Widget popUp(BuildContext context) {
  showMenu(context: context,position: RelativeRect.fromLTRB(width/3, height/3, width/2, height/2), items: <PopupMenuEntry>[
    PopupMenuItem<MenuEnum>(
      value: MenuEnum.changeName,
      child: InkWell(
        onTap:() {
          debugPrint("oldu amk");
        },
        child: Text("Change Name",
            style: TextStyle(
              fontSize: 15,
            )),
      ),
    ),
    const PopupMenuItem<MenuEnum>(
      value: MenuEnum.delete,
      child: Text(
        "Delete",
        style: TextStyle(fontSize: 15),
      ),
    ),
    ],);


    /*
    * const PopupMenuItem<MenuEnum>(
          value: MenuEnum.changeName,
          child: Text("Change Name",
              style: TextStyle(
                fontSize: 15,
              )),
        ),
        const PopupMenuItem<MenuEnum>(
          value: MenuEnum.delete,
          child: Text(
            "Delete",
            style: TextStyle(fontSize: 15),
          ),
        ),*/
  }

  void deleteCustomFolder() async{
    if(selectedIndex>3 && photoMainCategory.length-1!=selectedIndex){
      setState(() {
        photoMainCategory.removeAt(selectedIndex);
      });
      SharedPreferences folderName = await SharedPreferences.getInstance();
      await folderName.setString('folder'+(selectedIndex+1).toString(), null);
    }
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

  Widget _cameraToggleRowWidget() {
    if (cameras == null || cameras.isEmpty) {
      return Spacer();
    }
    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;

    return Container(
      width: width*0.33,
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
  Future<void> getStorage() async {
    final directory = await getExternalStorageDirectory();
    setState(() => externalDirectory = directory);
  }

  Future<void> pick(BuildContext context) async{
    Directory newDirectory = await DirectoryPicker.pick(
        context: context,
        rootDirectory: externalDirectory
    );

    if (newDirectory != null) {
    } else {
      // User cancelled without picking any directory
    }
  }
  Widget _cameraControlWidget(context) {
    return Container(
      width: width*0.33,
      child: FloatingActionButton(
        child: Icon(
          Icons.camera,
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
        onPressed: () {
//          pick(context);
          getPermissions();
//          _onCapturePressed();
        },
      ),
    );
  }
  Future<void> getPermissions() async {
    final permissions =
    await Permission.getPermissionsStatus([PermissionName.Storage]);
    var request = true;
    switch (permissions[0].permissionStatus ) {
      case PermissionStatus.allow:
        request = false;
        break;
      case PermissionStatus.always:
        request = false;
        break;
      default:
    }
    if (request) {
      await Permission.requestPermissions([PermissionName.Storage]);
      _onCapturePressed();
    }
  }
  _getPreviewPicture(context) {

    String path;
    String path2;

    path2 = "assets/images/blackpicture.png";
    if(lastPicturePath !=null){
      path = lastPicturePath.getString('path');
    }

    return Container(
      width: width*0.33,
      child: InkWell(
        onTap: (){
          if(path!=null)
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PreviewScreen(
                  imgPath: path,
                )),
          );
        },
        child: Container(
          width: 75,
          height: 75,
          // TODO Önceki Resim Getirilecek
          decoration: BoxDecoration(
                image: DecorationImage(image: path ==null ? AssetImage(path2) : FileImage(File(path))),
              ),
        ),
      ),
    );
  }

  void _showCameraException(CameraException e) {
    String errorText = 'Error:${e.code}\nError message : ${e.description}';
    print(errorText);
  }

  void _onSwitchCamera() {
    selectedCameraIndex =
        selectedCameraIndex < cameras.length - 1 ? selectedCameraIndex + 1 : 0;
    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    _initCameraController(selectedCamera);
  }

  void _onCapturePressed() async {
    try {
      callFileMethod(photoMainCategory[selectedIndex]);
      final path =
          join("/storage/emulated/0/DCIM/"+photoMainCategory[selectedIndex]+"/", '${DateTime.now()}.png');
      await controller.takePicture(path);
      debugPrint(path);

      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          isCaptured = false;
        });
      });
      setState(() {
        isCaptured = true;
      });
      SharedPreferences lastPicturePath = await SharedPreferences.getInstance();
      await lastPicturePath.setString('path', path);

      ImageGallerySaver.saveFile(path);
    } catch (e) {
      _showCameraException(e);
    }
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
            controller: klasorAdicontroller,
            decoration: InputDecoration(),
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Ok"),
              onPressed: () {
                int length = photoMainCategory.length - 1;
                setState(() {
                  photoMainCategory.insert(
                      length, klasorAdicontroller.text);
                  debugPrint("folder"+(length+1).toString());
                  lastPicturePath.setString("folder"+(length+1+1).toString(), klasorAdicontroller.text);
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

  void _changeFolderName(context) {
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
            controller: klasorAdicontroller,
            decoration: InputDecoration(),
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Okey"),
              onPressed: () {
                setState(() {
                  photoMainCategory[selectedIndex] = klasorAdicontroller.text;
                });
                lastPicturePath.setString("folder"+(selectedIndex+1).toString(), klasorAdicontroller.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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

  callFileMethod(fileName) async {
    String folderInAppDocDir =
        await AppUtil.createFolderInAppDocDir(fileName.toString());
  }
}

class AppUtil {
  static Future<String> createFolderInAppDocDir(String folderName) async {
    //Get this App Document Directory
    final Directory _appDocDir = Directory("/storage/emulated/0/DCIM");
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
