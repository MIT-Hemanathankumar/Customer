import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user/presenter/login_screen_presenter.dart';
import 'package:user/ui/all_reminder.dart';
import 'package:user/ui/change_password_profile.dart';
import 'package:user/ui/emptyscreen.dart';
import 'package:user/ui/main_page.dart';
import 'package:user/ui/my_medicine.dart';
import 'package:user/ui/profile_basicinfo.dart';
import 'package:user/ui/profile_delivery_area.dart';
import 'package:user/ui/splash_screen.dart';

import '../data/AuthState.dart';
import '../data/DatabaseHelper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog/progress_dialog.dart';

class Setting extends StatefulWidget {
  static String tag = 'place_order-screen';

  @override
  State<StatefulWidget> createState() {
    return new SettingState();
  }
}

class SettingState extends State<Setting>
    implements AuthStateListener {
  BuildContext _ctx;
  Future<File> imageFile;
  double opacity = 0.0;
  var yetToStartColor = const Color(0xFFF8A340);

  bool _isLoading = true;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String _username, _password;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  ProgressDialog progressDialog;

  PlaceOrderState() {
    var authStateProvider = new AuthStateProvider();
    authStateProvider.subscribe(this);
  }

  void _showSnackBar(String text) {
    Fluttertoast.showToast(
        msg: text,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
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
    setState(() => _isLoading = false);
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('name') ?? null;
  }

  @override
  void initState() {
    super.initState();
    init();
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future onSelectNotification(String payload) async {
    showDialog(
      context: context,
      builder: (_) {
        return new AlertDialog(
          title: Text("PayLoad"),
          content: Text("Payload : $payload"),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _ctx = context;
    progressDialog = new ProgressDialog(context);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    progressDialog.style(
        message: "Please wait...",
        borderRadius: 4.0,
        backgroundColor: Colors.white);

    var reminder2 = Padding(
      padding: const EdgeInsets.only(top: 2, left: 10, right: 10),
      child: new Card(
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: new FlatButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => MyMedicine(true, true)));
              },
              child: new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [new Text("Order Reminder"), Icon(Icons.arrow_forward)]),
              padding: EdgeInsets.all(12),
            ),
          )),
    );

    const PrimaryColor = const Color(0xFFffffff);
    const titleColor = const Color(0xFF151026);
    return new Scaffold(
        appBar: AppBar(
          elevation: 0.5,
          centerTitle: true,
          title: const Text('SETTING', style: TextStyle(color: Colors.black)),
          backgroundColor: PrimaryColor,
          leading: new Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context, false);
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.arrow_back),
                ),
              )),
        ),
        key: scaffoldKey,
        body: SafeArea(
          child: Column(children: [
            new Expanded(
                child: new ListView(
              children: <Widget>[
                reminder2,
              ],
            )),
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
  }
}

class DolDurmaClipper extends CustomClipper<Path> {
  DolDurmaClipper({@required this.right, @required this.holeRadius});

  final double right;
  final double holeRadius;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - right - holeRadius, 0.0)
      /* ..arcToPoint(
        Offset(size.width - right, 0),
        clockwise: false,
        radius: Radius.circular(1),
      )*/
      ..lineTo(size.width, 0.0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width - right, size.height)
      ..arcToPoint(
        Offset(size.width - right - holeRadius, size.height),
        clockwise: false,
        radius: Radius.circular(1),
      );

    path.lineTo(0.0, size.height);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(DolDurmaClipper oldClipper) => true;
}
