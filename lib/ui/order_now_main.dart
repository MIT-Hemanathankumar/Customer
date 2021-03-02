import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/presenter/login_screen_presenter.dart';
import 'package:user/ui/main_page.dart';
import 'package:user/ui/place_order.dart';
import 'package:user/ui/profile.dart';
import 'package:user/ui/signup.dart';
import 'package:user/ui/signup_page.dart';
import 'package:user/ui/splash_screen.dart';

import '../data/AuthState.dart';
import '../data/DatabaseHelper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog/progress_dialog.dart';

class OrderOption extends StatefulWidget {
  static String tag = 'place_order-screen';

  final bool showBackarrow;

  OrderOption(this.showBackarrow);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new OrderOptionState();
  }
}

class OrderOptionState extends State<OrderOption>
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

  ProgressDialog progressDialog;

  PlaceOrderState() {
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
      setState(() => _isLoading = false);
      final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('name') ?? "";
  }

  @override
  void initState() {
    super.initState();
    init();
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

    var onetimelayout = Padding(
      padding: const EdgeInsets.all(10),
      child: new Card(
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: new FlatButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => PlaceOrder(orderType: "1")));
              },
              child: new Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    new Center(
                      child:  new Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Image.asset('assets/add.png'),
                            ),
                          )),
                    ),
                    new Text("One Time",style: TextStyle(fontSize: 16))]),
              padding: EdgeInsets.all(14),
            ),
          )),
    );

    var repeatlayout = Padding(
      padding: const EdgeInsets.all(10),
      child: new Card(
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: new FlatButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => PlaceOrder(orderType: "2")));
              },
              child: new Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    new Center(
                      child:  new Padding(
                          padding: const EdgeInsets.all(0),
                          child: GestureDetector(
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Image.asset('assets/add.png'),
                            ),
                          )),
                    ),
                    new Text("Repeat Time",style: TextStyle(fontSize: 16),),]),
              padding: EdgeInsets.all(14),
            ),
          )),
    );
    var prescriptionlayout = Padding(
      padding: const EdgeInsets.all(10),
      child: new Card(
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: new FlatButton(
              onPressed: () {
                Navigator.push(
                  _ctx,
                  MaterialPageRoute(builder: (context) => ConfirmOrderScreen(null, "3")),
                );
              },
              child: new Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    new Center(
                      child:  new Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Image.asset('assets/add.png'),
                            ),
                          )),
                    ),
                    new Text("Order with your repeat Prescription",style: TextStyle(fontSize: 16)),]),
              padding: EdgeInsets.all(14),
            ),
          )),
    );

    const PrimaryColor = const Color(0xFFffffff);
    const titleColor = const Color(0xFF151026);
    return new Scaffold(
        appBar: AppBar(
          elevation: 0.5,
          centerTitle: true,
          title: const Text('ORDER TYPE', style: TextStyle(color: Colors.black)),
          backgroundColor: PrimaryColor,
          leading: widget.showBackarrow == true ? new Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context, false);
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.arrow_back),
                ),
              )) : SizedBox(width: 1,),
          actions: <Widget>[
            new Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: (){ Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Profile()));},
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child:Image.asset('assets/dot.png'),
                  ),
                ))
          ],
        ),
        key: scaffoldKey,
        body: SafeArea(
          child: Column(children: [
            new Expanded(
                child: new ListView(
              children: <Widget>[onetimelayout, repeatlayout, prescriptionlayout],
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
