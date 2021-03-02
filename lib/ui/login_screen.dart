import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/data/rest_ds.dart';
import 'package:user/model/User.dart';
import 'package:user/presenter/login_screen_presenter.dart';
import 'package:user/ui/main_page.dart';
import 'package:user/ui/signup.dart';
import 'package:user/ui/signup_page.dart';
import 'package:user/util/network_utils.dart';

import '../data/AuthState.dart';
import '../data/DatabaseHelper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:progress_dialog/progress_dialog.dart';

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

class LoginScreen extends StatefulWidget {
  static String tag = 'login-screen';

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new LoginScreenState();
  }
}

class LoginScreenState extends State<LoginScreen>
    implements LoginScreenContract, AuthStateListener {
  BuildContext _ctx;
  Future<File> imageFile;
  double opacity = 0.0;
  var yetToStartColor = const Color(0xFFF8A340);

  bool _isLoading = true;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String _username, _password;
  TextEditingController emailController = TextEditingController();
  LoginScreenPresenter _presenter;

  ProgressDialog progressDialog;
  var connectivityResult;

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

  Widget showImage() {
    return FutureBuilder<File>(
      future: imageFile,
      builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return Image.file(
            snapshot.data,
            width: 300,
            height: 300,
          );
        } else if (snapshot.error != null) {
          return const Text(
            'Error Picking Image',
            textAlign: TextAlign.center,
          );
        } else {
          return const Text(
            'No Image Selected',
            textAlign: TextAlign.center,
          );
        }
      },
    );
  }

  void _submit() {
    final form = formKey.currentState;
    if (form.validate()) {
      progressDialog.show();
      // setState(() => _isLoading = true);
      form.save();
      _presenter.doLogin(_username, _password);
    }
  }

  void forgotpass() {
    final form = formKey.currentState;
    if (emailController.text != null && emailController.text != "") {
      progressDialog.show();
      forgotApi(emailController.text);
    } else {
      _showSnackBar("Enter Email");
    }
  }

  Future<Map<String, Object>> forgotApi(String email) async {
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-type': 'application/json',
    };

    final response = await http.get(RestDatasource.FORGOT_PASSWORD_URL + email,
        headers: headers);
    progressDialog.hide();
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, Object> data = json.decode(response.body);
      //orderType  orderStatusDesc  "orderDate"  orderId
      try {
        // if (data.containsKey("data")) {
        if (data == null) {
          _showSnackBar("No Data Found");
        } else {
          print(data.toString());
          var status = data['status'];
          var uName = data['message'];
          _showItemDialog(uName);
        }
      } catch (e) {
        _showSnackBar(e);
      }
    } else if (response.statusCode == 401) {
      _showSnackBar('Something went wrong');
    } else {
      _showSnackBar('Something went wrong');
    }
  }

  Widget _showItemDialog(String message) {
    return AlertDialog(
      content: Text(message),
      actions: <Widget>[
        FlatButton(
          child: const Text('CLOSE'),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
      ],
    );
  }

  void _showSnackBar(String text) {
    //  scaffoldKey.currentState
    //    .showSnackBar(new SnackBar(content: new Text(text)));
    Fluttertoast.showToast(
        msg: text,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  @override
  onAuthStateChanged(AuthState state) {
    if (state == AuthState.LOGGED_IN)
      Navigator.of(_ctx).pushReplacementNamed("/home");
  }

  void init() async {
    var db = new DatabaseHelper();
    var isLoggedIn = await db.isLoggedIn();
    new Future.delayed(const Duration(seconds: 2), () {
      if (isLoggedIn) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => Home(),
            ),
            ModalRoute.withName('/login_screen'));
      } else {
        setState(() {
          opacity = 1.0;
        });
      }
      setState(() => _isLoading = false);
    });
  }

  @override
  void initState() {
    super.initState();
    connectivityResult = (Connectivity().checkConnectivity());
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
        color: yetToStartColor,
        textColor: Colors.white,
      ),
    );

    var bottomButtons = new Column(
      children: <Widget>[
        new SizedBox(
          child: Container(
            margin: const EdgeInsets.only(top: 50.0),
            color: Colors.white,
            alignment: Alignment.center,
            child: Column(
              children: <Widget>[
                new FlatButton(
                  onPressed: () {
                    // Navigator.of(context).pushNamed(SignupPage.tag);
                    showDialog(
                      context: context,
                      builder: (_) => LogoutOverlay(),
                    );
                  },
                  child: new Text("Forgot Password?"),
                  padding: EdgeInsets.all(12),
                ),
                /* new Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: new ButtonTheme(
                      minWidth: 230,
                      height: 45,
                      child: new FlatButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => BasicSignupScreen()));
                        },
                        child: new Text("SIGNUP"),
                        color: Colors.transparent,
                        textColor: Colors.blue,
                      ),
                    ))*/
              ],
            ),
          ),
        )
      ],
    );

    var loginForm = new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Form(
          key: formKey,
          child: new Column(children: <Widget>[
            new Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  height: 50,
                  child: new TextFormField(
                    onSaved: (val) => _username = val,
                    validator: (val) {
                      return val.trim().isEmpty ? "Enter Username" : null;
                    },
                    //initialValue: "rc1.cust20200101@gmail.com",
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: false,
                    decoration: new InputDecoration(
                        labelText: "Username",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focus);
                    },
                  ),
                )),
            new Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  height: 50,
                  child: new TextFormField(
                    onSaved: (val) => _password = val,
                    keyboardType: TextInputType.visiblePassword,
                    focusNode: focus,
                    validator: (val) {
                      return val.trim().isEmpty ? "Enter Password" : null;
                    },
                    obscureText: true,
                    //initialValue: "Qsl_1633",
                    decoration: new InputDecoration(
                        labelText: "Password",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                  ),
                )),
            loginBtn,
            /* showImage(),
            RaisedButton(
              child: Text("Select Image from Gallery"),
              onPressed: () {
                pickImageFromGallery(ImageSource.gallery);
              },
            ),*/
          ]),
        ),
        // _isLoading ? new CircularProgressIndicator() : SizedBox(height: 8.0),
      ],
    );
    const PrimaryColor = const Color(0xFFffffff);
    const titleColor = const Color(0xFF151026);
    return new Scaffold(
        appBar: AppBar(
          elevation: 0.5,
          centerTitle: true,
          title: const Text('Login', style: TextStyle(color: Colors.black)),
          backgroundColor: PrimaryColor,
        ),
        key: scaffoldKey,
        body: SafeArea(
          child: Column(children: [
            new Expanded(
                child: new Center(
                    child: new Container(
                        height: 370,
                        child: GridView.count(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(20.0),
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          crossAxisCount: 1,
                          children: <Widget>[loginForm],
                        )))),
            bottomButtons
          ]),
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
    var uName = user['message'];

    try {
      if (status == true) {
        // {"userId":0,"name":null,"email":null,"mobile":null,"token":null,"error":null,"userType":null,"status":false,"message":"User does not exist"}
        String userId = user['userId'].toString();
        String token = user['token'].toString();
        String name = user['name'].toString();
        String email = user['email'].toString();
        String mobile = user['mobile'].toString();
        String customerId = user['customerId'].toString();
        User u = new User(userId, token, name, email, mobile);
        // await db.saveUser(u);
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', token);
        prefs.setString('userId', userId);
        prefs.setString('name', name);
        prefs.setString('email', email);
        prefs.setString('mobile', mobile);
        prefs.setString('customerId', customerId);
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
      } else {
        _showSnackBar(uName);
      }
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }
}

class LogoutOverlay extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LogoutOverlayState();
}

class LogoutOverlayState extends State<LogoutOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> scaleAnimation;
  TextEditingController emailController = TextEditingController();
  ProgressDialog progressDialog;
  final focusfName = FocusNode();
  String _username;
  BuildContext _ctx;
  var yetToStartColor = const Color(0xFFF8A340);

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 350));
    scaleAnimation =
        CurvedAnimation(parent: controller, curve: Curves.elasticInOut);

    controller.addListener(() {
      setState(() {});
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    _ctx = context;
    progressDialog = new ProgressDialog(context);

   /// SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    progressDialog.style(
        message: "Please wait...",
        borderRadius: 4.0,
        backgroundColor: Colors.white);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Container(
              margin: EdgeInsets.all(20.0),
              padding: EdgeInsets.all(15.0),
              height: 330.0,
              decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0))),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 50,
                  ),
                  new Text(
                    "Forgot Password",
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  new Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        height: 50,
                        child: new TextFormField(
                          onSaved: (val) => _username = val,
                          validator: (val) {
                            return val.trim().isEmpty ? "Enter Email" : null;
                          },
                          controller: emailController,
                          onFieldSubmitted: (v) {
                            FocusScope.of(context).requestFocus(focusfName);
                          },
                          ////initialValue: "rc2.cust20200101@gmail.com",
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          autofocus: false,
                          decoration: new InputDecoration(
                              labelText: "Email",
                              border: new OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                      const Radius.circular(5.0)))),
                        ),
                      )),
                  SizedBox(
                    height: 50,
                  ),
                  Expanded(
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                          padding: const EdgeInsets.only(
                              left: 20.0, right: 10.0, top: 10.0, bottom: 10.0),
                          child: ButtonTheme(
                              height: 35.0,
                              minWidth: 110.0,
                              child: RaisedButton(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0)),
                                splashColor: Colors.white.withAlpha(40),
                                child: Text(
                                  'Cancel',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.0),
                                ),
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                              ))),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ButtonTheme(
                            height: 35.0,
                            minWidth: 110.0,
                            child: RaisedButton(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0)),
                              splashColor: Colors.white.withAlpha(40),
                              child: Text(
                                'Submit',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: yetToStartColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.0),
                              ),
                              onPressed: () {
                                forgotpass();
                              },
                            )),
                      ),
                    ],
                  )),
                  SizedBox(
                    height: 10,
                  ),
                ],
              )),
        ),
      ),
    );
  }

  void forgotpass() {
    if (emailController.text != null && emailController.text != "") {
      progressDialog.show();
      forgotApi(emailController.text);
    } else {
      _showSnackBar("Enter Email");
    }
  }

  Future<Map<String, Object>> forgotApi(String email) async {
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-type': 'application/json',
    };

    final response = await http.post(RestDatasource.FORGOT_PASSWORD_URL + email,
        headers: headers);
    progressDialog.hide();
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, Object> data = json.decode(response.body);
      //orderType  orderStatusDesc  "orderDate"  orderId
      try {
        // if (data.containsKey("data")) {
        if (data == null) {
          _showSnackBar("No Data Found");
        } else {
          print(data.toString());
          var status = data['status'];
          var uName = data['message'];
          if (status == true) {
            //Navigator.pop(context, false);
            _showItemDialog('Verification link sent to  $email');
          } else {
            _showSnackBar(uName);
          }
        }
      } catch (e) {
        _showSnackBar(e);
      }
    } else if (response.statusCode == 401) {
      _showSnackBar('Something went wrong');
    } else {
      _showSnackBar('Something went wrong');
    }
  }

  void _showItemDialog(String message) {
    Widget okButton = FlatButton(
      child: Text("Okay"),
      onPressed: () {
        Navigator.pop(context, false);
        Navigator.pop(context, false);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(""),
      content: Container(
        height: 140.0,
        decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0))),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFC5FBC5),
              child: Image.asset(
                'assets/tick.png',
                width: 70,
                height: 70,
              ),
            ),
            SizedBox(height: 8),
            Text(message)
          ],
        ),
      ),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void _showSnackBar(String text) {
    Fluttertoast.showToast(
        msg: text,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}
