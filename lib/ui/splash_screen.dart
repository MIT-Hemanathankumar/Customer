import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/presenter/login_screen_presenter.dart';
import 'package:user/ui/login_screen.dart';
import 'package:user/ui/main_page.dart';
import 'package:user/ui/signup.dart';

import '../data/AuthState.dart';
import '../data/DatabaseHelper.dart';

const CameraAccessDenied = 'PERMISSION_NOT_GRANTED';

/// method channel.
const MethodChannel _channel = const MethodChannel('qr_scan');

/// Scanning Bar Code or QR Code return content
Future<String> scan() async => await _channel.invokeMethod('scan');

/// Scanning Photo Bar Code or QR Code return content
Future<String> scanPhoto() async => await _channel.invokeMethod('scan_photo');

// Scanning the image of the specified path
Future<String> scanPath(String path) async {
  assert(path != null && path.isNotEmpty);
  Fluttertoast.showToast(
      msg: "This is Center Short Toast",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIos: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0);
  return await _channel.invokeMethod('scan_path', {"path": path});
}

// Parse to code string with uint8list
Future<String> scanBytes(Uint8List uint8list) async {
  assert(uint8list != null && uint8list.isNotEmpty);
  return await _channel.invokeMethod('scan_bytes', {"bytes": uint8list});
}

/// Generating Bar Code Uint8List
Future<Uint8List> generateBarCode(String code) async {
  assert(code != null && code.isNotEmpty);
  return await _channel.invokeMethod('generate_barcode', {"code": code});
}

class SplashScreen extends StatefulWidget {
  static String tag = 'login-screen';

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new SplashScreenState();
  }
}

class SplashScreenState extends State<SplashScreen>
    implements LoginScreenContract, AuthStateListener {
  BuildContext _ctx;
  Future<File> imageFile;
  double opacity = 0.0;
  String userId, token;
  bool _isLoading = true;
  bool _showbutton = false;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String _username, _password;
  var connectivityResult;

  LoginScreenPresenter _presenter;

  ProgressDialog progressDialog;
  var yetToStartColor = const Color(0xFFF8A340);

  LoginScreenState() {
    _presenter = new LoginScreenPresenter(this);

    var authStateProvider = new AuthStateProvider();
    authStateProvider.subscribe(this);
  }

  pickImageFromGallery(ImageSource source) {
    setState(() {
      imageFile = ImagePicker.pickImage(source: source);
    });
  }

  void _submit() async {
    connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => LoginScreen()));
    } else {
      _showSnackBar("No internet connection");
    }
    /* final form = formKey.currentState;
    if (form.validate()) {
      progressDialog.show();
      // setState(() => _isLoading = true);
      form.save();
      _presenter.doLogin(_username, _password);
    }*/
  }

  void _signup() async {
    connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => BasicSignupScreen()));
    } else {
      _showSnackBar("No internet connection");
    }
    /* final form = formKey.currentState;
    if (form.validate()) {
      progressDialog.show();
      // setState(() => _isLoading = true);
      form.save();
      _presenter.doLogin(_username, _password);
    }*/
  }

  void _showSnackBar(String text) {
    scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  onAuthStateChanged(AuthState state) {
    if (state == AuthState.LOGGED_IN)
      Navigator.of(_ctx).pushReplacementNamed("/home");
  }

  void init() async {
    var db = new DatabaseHelper();
    /* var isLoggedIn = await db.isLoggedIn();
    List<dynamic> userData = await db.getAll();
    for (int i = 0; i < userData.length; i++) {
      try {
        userId = userData[i]["userId"];
        token = userData[i]["token"];
      } catch (e) {
        print(e);
      }
      //if (userId != null) _homeMenuPresenter.getData(userId, userType);
    }*/
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? "";
    userId = prefs.getString('userId') ?? "";
    new Future.delayed(const Duration(seconds: 2), () {
      if (userId != null && userId.isNotEmpty) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => Home(),
            ),
            ModalRoute.withName('/login_screen'));
      } else {
        setState(() => _isLoading = false);
        setState(() => _showbutton = true);
      }
      /*else {
//        setState(() {
//          opacity = 1.0;
//        });
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => LoginScreen(),
            ),
            ModalRoute.withName('/login_screen'));
      }*/
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      opacity = 1.0;
    });
    init();
  }

  @override
  Widget build(BuildContext context) {
    _ctx = context;
    progressDialog = new ProgressDialog(context);

    /*SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.black, statusBarBrightness: Brightness.light));*/
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    var db = new DatabaseHelper();
    //var list = db.getAll();
    // List<User> list = db.getAll() as List<User>;
    // Fluttertoast.showToast(msg: "w", toastLength: Toast.LENGTH_LONG);

    progressDialog.style(
        message: "Please wait...",
        borderRadius: 4.0,
        backgroundColor: Colors.white);
    final focus = FocusNode();
    var loginBtn = new ButtonTheme(
      minWidth: 230,
      height: 45,
      child: new RaisedButton(
        onPressed: _submit,
        child: new Text("LOGIN"),
        color: Colors.blue,
        textColor: Colors.white,
      ),
    );

    var logo = new Column(
      children: <Widget>[
        new Padding(
            padding: const EdgeInsets.only(left: 70.0, top: 30.0, right: 70.0),
            child: new SizedBox(
              child: Image.asset('assets/app_logo_new.png'),
            ))
      ],
    );

    var loginForm = new Padding(
      padding: const EdgeInsets.all(20),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          logo,
          new Padding(
              padding: const EdgeInsets.only(
                  left: 10.0, top: 10.0, right: 10.0, bottom: 40.0),
              child: new Text("Customer",
                  style: new TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                  textScaleFactor: 2.0,
                  textAlign: TextAlign.center)),
          _showbutton
              ? new ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: new ButtonTheme(
                    //  minWidth: 230,
                    height: 45,
                    child: new RaisedButton(
                      onPressed: _submit,
                      child: new Text("LOGIN"),
                      color: yetToStartColor,
                      textColor: Colors.white,
                    ),
                  ),
                )
              : SizedBox(height: 2.0),
          SizedBox(
            height: 15,
          ),
          _showbutton
              ? ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: new ButtonTheme(
                    //minWidth: 230,
                    height: 45,
                    child: new RaisedButton(
                      onPressed: _signup,
                      child: new Text("SIGNUP"),
                      color: yetToStartColor,
                      textColor: Colors.white,
                    ),
                  ),
                )
              : SizedBox(height: 2.0)
          //_isLoading ? new CircularProgressIndicator() : SizedBox(height: 8.0),
        ],
      ),
    );

    return new Scaffold(
        appBar: null,
        key: scaffoldKey,
        body: new Center(
          child: SafeArea(
              child: SingleChildScrollView(
                  child: new Center(
                      //height: double.infinity,
                      //color: Colors.white,
                      // child: new Center(
                      child: new Column(
            children: <Widget>[
              new AnimatedOpacity(
                  opacity: opacity,
                  duration: Duration(milliseconds: 1000),
                  child: new Align(
                    alignment: Alignment.center,
                    child: loginForm,
                  )
                  //),,
                  ),
              _isLoading
                  ? new CircularProgressIndicator()
                  : SizedBox(height: 8.0),
            ],
          )))),
          /* child: SingleChildScrollView(
            child: new Center(
                //height: double.infinity,
                //color: Colors.white,
                // child: new Center(
                child: new Align(
              alignment: Alignment.center,
              child: loginForm,
            )
                //),
                ),
          ),*/
        ));
  }

  @override
  void onLoginError(String errorTxt) {
    _showSnackBar(errorTxt);
    progressDialog.hide();
    //setState(() => _isLoading = false);
  }

  @override
  void onLoginSuccess(Map<String, Object> user) async {
    progressDialog.hide();
    // _showSnackBar(user.toString());
    //setState(() => _isLoading = false);
    var db = new DatabaseHelper();
    var status = user['status'];
    var uName = user['name'];
    if (status == 'true') {
      // Navigator.of(_ctx).pushNamed(HomePage.tag);
      // Navigator.push(_ctx, MaterialPageRoute(builder: (context) => HomePage()));
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => Home(),
          ),
          ModalRoute.withName('/login_screen'));
      /* var authStateProvider = new AuthStateProvider();
        authStateProvider.notify(AuthState.LOGGED_IN);*/
      // _showSnackBar("Login success");
    }
  }
}
