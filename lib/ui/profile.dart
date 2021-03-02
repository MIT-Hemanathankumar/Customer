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
import 'package:user/ui/setting.dart';
import 'package:user/ui/splash_screen.dart';

import '../data/AuthState.dart';
import '../data/DatabaseHelper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog/progress_dialog.dart';

class Profile extends StatefulWidget {
  static String tag = 'place_order-screen';

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new ProfileState();
  }
}

class ProfileState extends State<Profile>
    implements LoginScreenContract, AuthStateListener {
  BuildContext _ctx;
  Future<File> imageFile;
  double opacity = 0.0;
  var yetToStartColor = const Color(0xFFF8A340);

  bool _isLoading = true;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String _username, _password;

  LoginScreenPresenter _presenter;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  ProgressDialog progressDialog;

  PlaceOrderState() {
    _presenter = new LoginScreenPresenter(this);
    var authStateProvider = new AuthStateProvider();
    authStateProvider.subscribe(this);
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
      // progressDialog.show();
      // setState(() => _isLoading = true);
      //form.save();
      // _presenter.doLogin(_username, _password);
    }
  }

  void _showSnackBar(String text) {
    //  scaffoldKey.currentState
    //    .showSnackBar(new SnackBar(content: new Text(text)));
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
    var db = new DatabaseHelper();
    var isLoggedIn = await db.isLoggedIn();
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

  Future _showNotificationWithDefaultSound() async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'New Post',
      'How to Show Notification in Flutter',
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
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

  _launchCallURL(String url) async {
    final Uri bugMail = Uri(
        scheme: 'tel',
        path: url);
    if (await canLaunch(bugMail.toString())) {
      await launch(bugMail.toString());
    } else {
      _showSnackBar('Could not launch $url');
    }
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
    final focus = FocusNode();

    var banner = Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(bottom: 30),
          child: Container(
            //replace this Container with your Card
            color: Colors.white,
            height: 200.0,
            child: Image.asset(
              'assets/profile_banner.png',
              fit: BoxFit.fill,
            ),
          ),
        ),
        Positioned(
            bottom: 0.0,
            right: 0.0,
            left: 0.0,
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Color(0xfff58053),
                          borderRadius: BorderRadius.all(
                            Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey,
                              offset: Offset(0.0, 1.0), //(x,y)
                              blurRadius: 6.0,
                            ),
                          ],
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            _username != null
                                ? '${_username[0].toUpperCase()}'
                                : '',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  ],
                )))
      ],
    );
    var logout = Padding(
      padding: const EdgeInsets.only(left: 10, top: 2, right: 10, bottom: 10),
      child: new Card(
          child: Padding(
        padding: const EdgeInsets.all(0),
        child: new FlatButton(
          onPressed: () {
            // Navigator.of(context).pushNamed(SignupPage.tag);
            _asyncConfirmDialog();
          },
          child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [new Text("Logout"), Icon(Icons.arrow_forward)]),
          padding: EdgeInsets.all(12),
        ),
      )),
    );
    var basicinfo = Padding(
      padding: const EdgeInsets.only(top: 2, left: 10, right: 10),
      child: new Card(
          child: Padding(
        padding: const EdgeInsets.all(0),
        child: new FlatButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ProfileBasicinfo()));
          },
          child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [new Text("My Details"), Icon(Icons.arrow_forward)]),
          padding: EdgeInsets.all(12),
        ),
      )),
    );

    var reminder = Padding(
      padding: const EdgeInsets.only(top: 2, left: 10, right: 10),
      child: new Card(
          child: Padding(
        padding: const EdgeInsets.all(0),
        child: new FlatButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => MyMedicine(true, false)));
          },
          child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [new Text("My Medicine"), Icon(Icons.arrow_forward)]),
          padding: EdgeInsets.all(12),
        ),
      )),
    );
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
    var reminders = Padding(
      padding: const EdgeInsets.only(top: 2, left: 10, right: 10),
      child: new Card(
          child: Padding(
        padding: const EdgeInsets.all(0),
        child: new FlatButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => AllRemainder()));
            /* Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ReminderHomeNew()));*/
          },
          child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [new Text("Reminders"), Icon(Icons.arrow_forward)]),
          padding: EdgeInsets.all(12),
        ),
      )),
    );
    var changePassword = Padding(
      padding: const EdgeInsets.only(top: 2, left: 10, right: 10),
      child: new Card(
          child: Padding(
        padding: const EdgeInsets.all(0),
        child: new FlatButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ChangePasswordHome()));
          },
          child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                new Text("Change Password"),
                Icon(Icons.arrow_forward)
              ]),
          padding: EdgeInsets.all(12),
        ),
      )),
    );
    var setting = Padding(
      padding: const EdgeInsets.only(top: 2, left: 10, right: 10),
      child: new Card(
          child: Padding(
        padding: const EdgeInsets.all(0),
        child: new FlatButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => Setting()));
          },
          child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [new Text("Setting"), Icon(Icons.arrow_forward)]),
          padding: EdgeInsets.all(12),
        ),
      )),
    );
    var contactUs = Padding(
      padding: const EdgeInsets.only(top: 2, left: 10, right: 10),
      child: new Card(
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: new FlatButton(
              onPressed: () {
                _launchCallURL("+919488084484");
              },
              child: new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [new Text("Contact Us"), Icon(Icons.arrow_forward)]),
              padding: EdgeInsets.all(12),
            ),
          )),
    );
    var setDeliveryArea = Padding(
      padding: const EdgeInsets.only(top: 2, left: 10, right: 10),
      child: new Card(
          child: Padding(
        padding: const EdgeInsets.all(0),
        child: new FlatButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => DeliveryArea()));
          },
          child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                new Text("Delivery Address"),
                Icon(Icons.arrow_forward)
              ]),
          padding: EdgeInsets.all(12),
        ),
      )),
    );
    var privacy = Padding(
      padding: const EdgeInsets.only(top: 2, left: 10, right: 10),
      child: new Card(
          child: Padding(
        padding: const EdgeInsets.all(0),
        child: new FlatButton(
          onPressed: () {
            // Navigator.of(context).pushNamed(SignupPage.tag);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => EmptyApp(true)));
          },
          child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                new Text("Privacy Policy"),
                Icon(Icons.arrow_forward)
              ]),
          padding: EdgeInsets.all(12),
        ),
      )),
    );
    var terms = Padding(
      padding: const EdgeInsets.only(top: 2, left: 10, right: 10),
      child: new Card(
          child: Padding(
        padding: const EdgeInsets.all(0),
        child: new FlatButton(
          onPressed: () {
            // Navigator.of(context).pushNamed(SignupPage.tag);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => EmptyApp(true)));
          },
          child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [new Text("Terms of use"), Icon(Icons.arrow_forward)]),
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
          title: const Text('PROFILE', style: TextStyle(color: Colors.black)),
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
                banner,
                basicinfo,
                reminder,
                changePassword,
                setting,
                //reminder2,
                setDeliveryArea,
                reminders,
                privacy,
                terms,
                logout,
                Center(
                    child: Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 20),
                  child: Text('version 1.05', style: TextStyle(fontSize: 11),),
                ))
              ],
            )),
          ]),
        ));
  }

  void _asyncConfirmDialog() {
    showDialog<ConfirmAction>(
      context: context,
      barrierDismissible: false, // user must tap button for close dialog!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: const Text('Are you sure to logout?'),
          actions: <Widget>[
            FlatButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.pop(_ctx);
              },
            ),
            FlatButton(
              child: const Text('YES'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                prefs.remove('token');
                prefs.remove('userId');
                prefs.remove('name');
                prefs.remove('email');
                prefs.remove('mobile');
                Navigator.pushAndRemoveUntil(
                    context,
                    PageRouteBuilder(pageBuilder: (BuildContext context,
                        Animation animation, Animation secondaryAnimation) {
                      return SplashScreen();
                    }, transitionsBuilder: (BuildContext context,
                        Animation<double> animation,
                        Animation<double> secondaryAnimation,
                        Widget child) {
                      return new SlideTransition(
                        position: new Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      );
                    }),
                    (Route route) => false);
              },
            )
          ],
        );
      },
    );
    // Navigator.pop(context, true);
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
