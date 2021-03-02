import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/customview/cam/core/helper.dart';
import 'package:user/customview/cam/darwin_camera.dart';
import 'package:user/data/rest_ds.dart';
import 'package:user/ui/camera.dart';
import 'package:user/ui/login_screen.dart';
import 'package:user/ui/main_page.dart';
import 'package:user/ui/mastermedicine.dart';
import 'package:user/ui/profile.dart';
import 'package:http/http.dart' as http;

import '../data/AuthState.dart';
import '../data/DatabaseHelper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog/progress_dialog.dart';

class PlaceOrder extends StatefulWidget {
  static String tag = 'place_order-screen';

  final String orderType;

  PlaceOrder({this.orderType});

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new PlaceOrderState();
  }
}

class PlaceOrderState extends State<PlaceOrder> implements AuthStateListener {
  BuildContext _ctx;
  Future<File> imageFile;
  double opacity = 0.0;
  var yetToStartColor = const Color(0xFFF8A340);

  bool _isLoading = true;
  String userId, token;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String _medicinename, _strength, _days;
  final List<String> names = <String>[
    'Aby',
    'Aish',
    'Ayan',
    'Ben',
    'Bob',
    'Charlie',
    'Cook',
    'Carline'
  ];
  final List<int> msgCount = <int>[2, 0, 10, 6, 52, 4, 0, 2];

  List<Map<String, dynamic>> array = List();

  ProgressDialog progressDialog;

  PlaceOrderState() {
    var authStateProvider = new AuthStateProvider();
    authStateProvider.subscribe(this);
  }

  void _submit() {
    if (array.length == 0) {
      _showSnackBar("Add min one Medicine");
    } else {
      List<Map<String, dynamic>> finalArray = List();
      for (int i = 0; i < array.length; i++) {
        if (array[i]["add"] == true) {
          finalArray.add(array[i]);
        }
      }
      if (finalArray.length > 0) {
        Navigator.push(
          _ctx,
          MaterialPageRoute(
              builder: (context) =>
                  ConfirmOrderScreen(finalArray, widget.orderType)),
        );
      } else {
        _showSnackBar("Add minimum one Item");
      }
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
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? "";
    userId = prefs.getString('userId') ?? "";
    if (userId != null) fetchMedicine();
  }

  methodInParent(Map<String, dynamic> map) => {
        setState(() {
          array.add(map);
        })
      };

  Future<Map<String, Object>> fetchMedicine() async {
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      "Content-type": "application/json",
      "Authorization": 'bearer $token'
    };

    final response = await http.get(RestDatasource.Customer_Medicines_LIST_URL,
        headers: headers);
    setState(() {
      _isLoading = false;
    });
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, Object> data = json.decode(response.body);
      progressDialog.hide();
      try {
        // if (data.containsKey("data")) {
        if (data == null) {
          _showSnackBar("No Data Found");
        } else {
          print(data.toString());
          List<dynamic> homelist = data['list'];
          if (homelist.length > 0) {
            setState(() {
              for (int i = 0; i < homelist.length; i++) {
                int m = 0;
                int no = 0;
                int e = 0;
                int ni = 0;
                int qty = 0;
                if (homelist[i]['morning'] == true) {
                  qty = qty + int.parse(_days);
                  m = 1;
                }
                if (homelist[i]['afterNoon'] == true) {
                  qty = qty + int.parse(_days);
                  no = 1;
                }
                if (homelist[i]['evening'] == true) {
                  qty = qty + int.parse(_days);
                  e = 1;
                }
                if (homelist[i]['night'] == true) {
                  qty = qty + int.parse(_days);
                  ni = 1;
                }
               /* var strength = "";
                if (homelist[i]['strength'] != null) {productId
                  strength = homelist[i]['strength'].toString();*/
                  Map<String, dynamic> map = {
                    "medicineName": homelist[i]['medicineName'].toString(),
                    "ProductId": homelist[i]['productId'].toString(),
                    //"strength": strength.toString(),
                    "duration": "28",
                    "quantity": 7,
                    "morning": 1,
                    "afterNoon": 1,
                    "evening": 1,
                    "night": 1,
                    "add": true
                  };
                  array.add(map);
                }
             // }
              //List<GroupModel> l = data["data"].cast<GroupModel>();
            });
          } else {
            _showSnackBar("No Data Found");
          }
        }
      } catch (e) {
        _showSnackBar(e);
      }
    } else if (response.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('token');
      prefs.remove('userId');
      prefs.remove('name');
      prefs.remove('email');
      prefs.remove('mobile');
      Navigator.pushAndRemoveUntil(
          _ctx,
          PageRouteBuilder(pageBuilder: (BuildContext context,
              Animation animation, Animation secondaryAnimation) {
            return LoginScreen();
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
      _showSnackBar('Token expired, Login again');
    } else {
      _showSnackBar('Something went wrong');
    }
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
        child: new Text("Create order"),
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
                new Padding(
                  padding: const EdgeInsets.all(10),
                  child: loginBtn,
                ),
              ],
            ),
          ),
        )
      ],
    );

    const PrimaryColor = const Color(0xFFffffff);
    const titleColor = const Color(0xFF151026);
    return new Scaffold(
        appBar: AppBar(
          elevation: 0.5,
          centerTitle: true,
          title: const Text('ADD MEDICINE',
              style: TextStyle(
                color: Colors.black,
              )),
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
          actions: <Widget>[
            new Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              AddItemScreen(function: methodInParent)),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Image.asset('assets/add.png'),
                  ),
                )),
          ],
        ),
        key: scaffoldKey,
        body: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      width: 170,
                      color: Colors.white,
                      //child:
                    ),
                  )),
            ),
            Padding(
                padding: const EdgeInsets.only(left: 2, right: 2, top: 2),
                child: new Container(
                    child: new Center(
                  child: _isLoading
                      ? new CircularProgressIndicator()
                      : SizedBox(height: 2.0),
                ))),
            new Expanded(
                child: ListView.builder(
                    padding: const EdgeInsets.all(0),
                    itemCount: array.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                          //height: 57,
                          margin: EdgeInsets.only(left: 4, right: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(0),
                            child: Card(
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Container(
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            //title: Text("Night"),
                                            onChanged: (bool value) {
                                              setState(() {
                                                //array.removeAt(index);
                                                if (value)
                                                  array[index]["add"] = true;
                                                else
                                                  array[index]["add"] = false;
                                              });
                                            },
                                            value: array[index]["add"],
                                          ),
                                         /* Text(
                                            "Medicine",
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey),
                                          ),*/
                                          SizedBox(
                                            width: 4,
                                          ),
                                          Flexible(
                                              child: new Container(
                                                child:  Column(
                                                  children: [
                                                    Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Text(
                                                        array[index]["medicineName"]
                                                            .toString(),
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                )
                                              ))
                                        ],
                                      ),
                                    ),
                                    flex: 4,
                                  ),
                                /*  Expanded(
                                    child: Container(
                                      child: Row(
                                        children: [
                                          Text(
                                            "Strength",
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey),
                                          ),
                                          SizedBox(
                                            width: 4,
                                          ),
                                          Expanded(
                                              child: Text(
                                            array[index]["strength"].toString(),
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black),
                                          ))
                                        ],
                                      ),
                                    ),
                                    flex: 2,
                                  ),*/
                                  Expanded(
                                    child: Container(
                                      child: Row(
                                        children: [
                                          Text(
                                            "Days",
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey),
                                          ),
                                          SizedBox(
                                            width: 4,
                                          ),
                                          Expanded(
                                              child: Text(
                                            array[index]["duration"].toString(),
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black),
                                          ))
                                        ],
                                      ),
                                    ),
                                    flex: 1,
                                  ),
                                ],
                              ),
                            ),
                          ));
                    })),
            bottomButtons
          ]),
        ));
  }

  void form() {
    try {} catch (e) {
      print(e);
    }
  }
}

/*class PermissionWidget extends StatefulWidget {
  /// Constructs a [PermissionWidget] for the supplied [Permission].
  const PermissionWidget(this._permission);

  final Permission _permission;

  @override
  _PermissionState createState() => _PermissionState(_permission);
}

class _PermissionState extends State<PermissionWidget> {
  _PermissionState(this._permission);

  final Permission _permission;
  PermissionStatus _permissionStatus = PermissionStatus.undetermined;

  @override
  void initState() {
    super.initState();

    _listenForPermissionStatus();
  }

  void _listenForPermissionStatus() async {
    final status = await _permission.status;
    setState(() => _permissionStatus = status);
  }

  Color getPermissionColor() {
    switch (_permissionStatus) {
      case PermissionStatus.denied:
        return Colors.red;
      case PermissionStatus.granted:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(_permission.toString()),
      subtitle: Text(
        _permissionStatus.toString(),
        style: TextStyle(color: getPermissionColor()),
      ),
      trailing: IconButton(
          icon: const Icon(Icons.info),
          onPressed: () {
            checkServiceStatus(context, _permission);
          }),
      onTap: () {
        requestPermission(_permission);
      },
    );
  }

  void checkServiceStatus(BuildContext context, Permission permission) async {
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text((await permission.status).toString()),
    ));
    _showSnackBar(permission.status.toString());
  }

  Future<void> requestPermission(Permission permission) async {
    final status = await permission.request();

    setState(() {
      print(status);
      _permissionStatus = status;
      _showSnackBar(_permissionStatus.toString());
    });
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
}*/

class AddItemScreen extends StatefulWidget {
  // Declare a field that holds the Todo.

  final Function function;

  // In the constructor, require a Todo.
  AddItemScreen({@required this.function});

  @override
  AddItemScreenState createState() => AddItemScreenState();
}

class AddItemScreenState extends State<AddItemScreen> {
  var yetToStartColor = const Color(0xFFF8A340);
  var blue = const Color(0xFF2188e5);
  String userId, token;
  ProgressDialog progressDialog;
  final focusfMedicine = FocusNode();
  final focuslStrenght = FocusNode();
  final focusmDays = FocusNode();
  final focuslMorning = FocusNode();
  final focuslNoon = FocusNode();
  final focuslEvening = FocusNode();
  final focuslNight = FocusNode();
  TextEditingController medicineController = TextEditingController();
  TextEditingController strenthController = TextEditingController();
  TextEditingController daysController = TextEditingController();
  TextEditingController morningController = TextEditingController();
  TextEditingController noonController = TextEditingController();
  TextEditingController eveningController = TextEditingController();
  TextEditingController nightController = TextEditingController();
  TextEditingController totalController = TextEditingController();
  bool _morning = true;
  bool _noon = true;
  bool _evening = true;
  bool _night = true;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String _medicinename, _strength, _days;
  var _productId;
  String _morningCount, _noonCount, _eveningCount, _nightCount, _total;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    super.dispose();
  }

  void init() async {
    setState(() {
      medicineController.text = "Medicine Name";
    });
  }

  @override
  void initState() {
    super.initState();
    init();
  }


  medicenenme(String map, var proId) => {
    setState(() {
      medicineController.text = map;
      _medicinename = map;
      _productId = proId;
    })
  };

  @override
  Widget build(BuildContext context) {
    const gray = const Color(0xFFEEEFEE);
    double c_width = MediaQuery.of(context).size.width * 0.6;
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0.5,
          backgroundColor: Colors.white,
          brightness: Brightness.light,
          iconTheme: IconThemeData(
            color: Colors.black, //c// hange your color here
          ),
          centerTitle: true,
          title: const Text('ADD NEW MEDICINE',
              style: TextStyle(color: Colors.black)),
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context, true);
              }),
          // centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: new Column(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      SizedBox(height: 20),
                      new Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          new Form(
                            key: formKey,
                            child: new Column(children: <Widget>[
                              new Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Container(
                                        //height: 45,
                                        decoration: ShapeDecoration(
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                                width: 1.0,
                                                style: BorderStyle.solid,
                                                color: Colors.grey),
                                            borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                          ),
                                        ),
                                        child: InkResponse(
                                          onTap: () async {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      SearchPage(function: medicenenme)),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              children: [
                                                Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Text(
                                                    medicineController.text,
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    flex: 1,
                                  )
                                ],
                              ),/*
                              new Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Container(
                                    height: 40,
                                    child: new TextFormField(
                                      onSaved: (val) => _medicinename = val,
                                      validator: (val) {
                                        return val.trim().isEmpty
                                            ? "Medicine name"
                                            : null;
                                      },
                                      //initialValue: "",
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.text,
                                      autofocus: false,
                                      controller: medicineController,
                                      onChanged: (_ctx) {
                                        if (medicineController.text != null &&
                                            medicineController.text.length > 0)
                                          _medicinename =
                                              medicineController.text;
                                      },
                                      decoration: new InputDecoration(
                                          labelText: "Medicine name",
                                          border: new OutlineInputBorder(
                                              borderRadius: const BorderRadius
                                                      .all(
                                                  const Radius.circular(5.0)))),
                                      onFieldSubmitted: (v) {
                                        FocusScope.of(context)
                                            .requestFocus(focusfMedicine);
                                      },
                                    ),
                                  )),*/
                             /* new Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Container(
                                    height: 40,
                                    child: new TextFormField(
                                      onSaved: (val) => _strength = val,
                                      validator: (val) {
                                        return val.trim().isEmpty
                                            ? "Strength"
                                            : null;
                                      },
                                      //initialValue: "",
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.number,
                                      focusNode: focusfMedicine,
                                      autofocus: false,
                                      controller: strenthController,
                                      onChanged: (_ctx) {
                                        if (strenthController.text != null &&
                                            strenthController.text.length > 0)
                                          _strength = strenthController.text;
                                      },
                                        inputFormatters: <TextInputFormatter>[
                                          WhitelistingTextInputFormatter.digitsOnly
                                        ],
                                      decoration: new InputDecoration(
                                          labelText: "Strength",
                                          border: new OutlineInputBorder(
                                              borderRadius: const BorderRadius
                                                      .all(
                                                  const Radius.circular(5.0)))),
                                      onFieldSubmitted: (v) {
                                        FocusScope.of(context)
                                            .requestFocus(focuslStrenght);
                                      },
                                    ),
                                  )),*/
                              new Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Container(
                                    height: 40,
                                    child: new TextFormField(
                                      onSaved: (val) => _days = val,
                                      keyboardType: TextInputType.number,
                                      focusNode: focuslStrenght,
                                      validator: (val) {
                                        return val.trim().isEmpty
                                            ? "Days"
                                            : null;
                                      },
                                      controller: daysController,
                                      onChanged: (_ctx) {
                                        if (daysController.text != null &&
                                            daysController.text.length > 0)
                                          _days = daysController.text;
                                      },
                                      inputFormatters: <TextInputFormatter>[
                                        WhitelistingTextInputFormatter.digitsOnly
                                      ],
                                      //initialValue: "",
                                      decoration: new InputDecoration(
                                          labelText: "Days",
                                          border: new OutlineInputBorder(
                                              borderRadius: const BorderRadius
                                                      .all(
                                                  const Radius.circular(5.0)))),
                                      onFieldSubmitted: (v) {
                                        FocusScope.of(context)
                                            .requestFocus(focusmDays);
                                      },
                                    ),
                                  )),
                              new Row(children: <Widget>[
                                SizedBox(
                                  width: 35,
                                ),
                                Container(
                                  width: 80,
                                  child: Text('Morning'),
                                ),
                                SizedBox(
                                  width: 6,
                                ),
                                Container(
                                  width: 100,
                                  height: 40,
                                  child: new TextFormField(
                                    onSaved: (val) => _morningCount = val,
                                    keyboardType: TextInputType.number,
                                    focusNode: focusmDays,
                                    validator: (val) {
                                      return val.trim().isEmpty ? "Days" : null;
                                    },
                                    controller: morningController,
                                    onChanged: (_ctx) {
                                      if (morningController.text != null &&
                                          morningController.text.length > 0)
                                        _morningCount = morningController.text;
                                    },
                                    inputFormatters: <TextInputFormatter>[
                                      WhitelistingTextInputFormatter.digitsOnly
                                    ],
                                    //initialValue: "",
                                    decoration: new InputDecoration(
                                        // labelText: "Days",
                                        border: new OutlineInputBorder(
                                            borderRadius: const BorderRadius
                                                    .all(
                                                const Radius.circular(5.0)))),
                                    onFieldSubmitted: (v) {
                                      FocusScope.of(context)
                                          .requestFocus(focuslMorning);
                                    },
                                  ),
                                )
                              ]),
                              SizedBox(
                                height: 8,
                              ),
                              new Row(children: <Widget>[
                                SizedBox(
                                  width: 35,
                                ),
                                Container(
                                  width: 80,
                                  child: Text('Noon'),
                                ),
                                SizedBox(
                                  width: 6,
                                ),
                                Container(
                                  width: 100,
                                  height: 40,
                                  child: new TextFormField(
                                    onSaved: (val) => _nightCount = val,
                                    keyboardType: TextInputType.number,
                                    focusNode: focuslMorning,
                                    validator: (val) {
                                      return val.trim().isEmpty ? "Days" : null;
                                    },
                                    controller: noonController,
                                    onChanged: (_ctx) {
                                      if (noonController.text != null &&
                                          noonController.text.length > 0)
                                        _noonCount = noonController.text;
                                    },
                                    inputFormatters: <TextInputFormatter>[
                                      WhitelistingTextInputFormatter.digitsOnly
                                    ],
                                    //initialValue: "",
                                    decoration: new InputDecoration(
                                        // labelText: "Days",
                                        border: new OutlineInputBorder(
                                            borderRadius: const BorderRadius
                                                    .all(
                                                const Radius.circular(5.0)))),
                                    onFieldSubmitted: (v) {
                                      FocusScope.of(context)
                                          .requestFocus(focuslNoon);
                                    },
                                  ),
                                )
                              ]),
                              SizedBox(
                                height: 8,
                              ),
                              new Row(children: <Widget>[
                                SizedBox(
                                  width: 35,
                                ),
                                Container(
                                  width: 80,
                                  child: Text('Evening'),
                                ),
                                SizedBox(
                                  width: 6,
                                ),
                                Container(
                                  width: 100,
                                  height: 40,
                                  child: new TextFormField(
                                    onSaved: (val) => _days = val,
                                    keyboardType: TextInputType.number,
                                    focusNode: focuslNoon,
                                    validator: (val) {
                                      return val.trim().isEmpty ? "Days" : null;
                                    },
                                    controller: eveningController,
                                    onChanged: (_ctx) {
                                      if (eveningController.text != null &&
                                          eveningController.text.length > 0)
                                        _eveningCount = eveningController.text;
                                    },
                                    inputFormatters: <TextInputFormatter>[
                                      WhitelistingTextInputFormatter.digitsOnly
                                    ],
                                    //initialValue: "",
                                    decoration: new InputDecoration(
                                        // labelText: "Days",
                                        border: new OutlineInputBorder(
                                            borderRadius: const BorderRadius
                                                    .all(
                                                const Radius.circular(5.0)))),
                                    onFieldSubmitted: (v) {
                                      FocusScope.of(context)
                                          .requestFocus(focuslEvening);
                                    },
                                  ),
                                )
                              ]),
                              SizedBox(
                                height: 8,
                              ),
                              new Row(children: <Widget>[
                                SizedBox(
                                  width: 35,
                                ),
                                Container(
                                  width: 80,
                                  child: Text('Night'),
                                ),
                                SizedBox(
                                  width: 6,
                                ),
                                Container(
                                  width: 100,
                                  height: 40,
                                  child: new TextFormField(
                                    onSaved: (val) => _days = val,
                                    keyboardType: TextInputType.number,
                                    focusNode: focuslEvening,
                                    validator: (val) {
                                      return val.trim().isEmpty ? "Days" : null;
                                    },
                                    controller: nightController,
                                    onChanged: (_ctx) {
                                      if (nightController.text != null &&
                                          nightController.text.length > 0)
                                        _nightCount = nightController.text;
                                    },
                                    inputFormatters: <TextInputFormatter>[
                                      WhitelistingTextInputFormatter.digitsOnly
                                    ],
                                    //initialValue: "",
                                    decoration: new InputDecoration(
                                        // labelText: "Days",
                                        border: new OutlineInputBorder(
                                            borderRadius: const BorderRadius
                                                    .all(
                                                const Radius.circular(5.0)))),
                                   /* onFieldSubmitted: (v) {
                                      FocusScope.of(context)
                                          .requestFocus(focuslNight);
                                    },*/
                                  ),
                                )
                              ]),
                              /* SizedBox(
                                height: 8,
                              ),
                              new Row(children: <Widget>[
                                SizedBox(
                                  width: 35,
                                ),
                                Container(
                                  width: 80,
                                  child: Text('Total'),
                                ),
                                SizedBox(
                                  width: 6,
                                ),
                                Container(
                                  width: 100,
                                  height: 40,
                                  child: new TextFormField(
                                    onSaved: (val) => _total = val,
                                    keyboardType: TextInputType.number,
                                    focusNode: focuslNight,
                                    validator: (val) {
                                      return val.trim().isEmpty ? "Days" : null;
                                    },
                                    controller: totalController,
                                    onChanged: (_ctx) {
                                      if (totalController.text != null &&
                                          totalController.text.length > 0)
                                        _total = totalController.text;
                                    },
                                    //initialValue: "",
                                    decoration: new InputDecoration(
                                        // labelText: "Days",
                                        border: new OutlineInputBorder(
                                            borderRadius: const BorderRadius
                                                    .all(
                                                const Radius.circular(5.0)))),
                                  ),
                                )
                              ]),
                               new Row(
                                children: <Widget>[
                                  Expanded(
                                    child: new Container(
                                      //color: deliverColor,
                                      margin: const EdgeInsets.all(3.0),
                                      padding: const EdgeInsets.only(
                                          left: 3.0,
                                          right: 3.0,
                                          top: 6.0,
                                          bottom: 6.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          Checkbox(
                                            //title: Text("Night"),
                                            onChanged: (bool value) {
                                              setState(() {
                                                _morning = value;
                                              });
                                            },
                                            value: _morning,
                                          ),
                                          Text("Morning",
                                              style: TextStyle(fontSize: 10))
                                        ],
                                      ),
                                    ),
                                    flex: 1,
                                  ),
                                  Expanded(
                                    child: new Container(
                                      //color: deliverColor,
                                      margin: const EdgeInsets.all(3.0),
                                      padding: const EdgeInsets.only(
                                          left: 3.0,
                                          right: 3.0,
                                          top: 6.0,
                                          bottom: 6.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          Checkbox(
                                            //title: Text("Night"),
                                            onChanged: (bool value) {
                                              setState(() {
                                                _noon = value;
                                              });
                                            },
                                            value: _noon,
                                          ),
                                          Text("Noon",
                                              style: TextStyle(fontSize: 10))
                                        ],
                                      ),
                                    ),
                                    flex: 1,
                                  ),
                                  Expanded(
                                    child: new Container(
                                      //color: deliverColor,
                                      margin: const EdgeInsets.all(3.0),
                                      padding: const EdgeInsets.only(
                                          left: 3.0,
                                          right: 3.0,
                                          top: 6.0,
                                          bottom: 6.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          Checkbox(
                                            //title: Text("Night"),
                                            onChanged: (bool value) {
                                              setState(() {
                                                _evening = value;
                                              });
                                            },
                                            value: _evening,
                                          ),
                                          Text("Evening",
                                              style: TextStyle(fontSize: 10))
                                        ],
                                      ),
                                    ),
                                    flex: 1,
                                  ),
                                  Expanded(
                                      child: new Container(
                                        //color: deliverColor,
                                        margin: const EdgeInsets.all(3.0),
                                        padding: const EdgeInsets.only(
                                            left: 3.0,
                                            right: 3.0,
                                            top: 6.0,
                                            bottom: 6.0),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Column(
                                          children: <Widget>[
                                            Checkbox(
                                              //title: Text("Night"),
                                              onChanged: (bool value) {
                                                setState(() {
                                                  _night = value;
                                                });
                                              },
                                              value: _night,
                                            ),
                                            Text(
                                              "Night",
                                              style: TextStyle(fontSize: 10),
                                            )
                                          ],
                                        ),
                                      ),
                                      flex: 1)
                                ],
                              ),*/
                            ]),
                          ),
                          new Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: GestureDetector(
                                onTap: () {
                                  if (_medicinename == null) {
                                    _showSnackBar("Enter medicine Name");
                                    return;
                                  }
                                  if (_medicinename == "Medicine Name") {
                                    _showSnackBar("Enter medicine Name");
                                    return;
                                  }
                                /*  if (_strength == null) {
                                    _showSnackBar("Enter strenth");
                                    return;
                                  }*/
                                  if (_days == null) {
                                    _showSnackBar("Enter day's");
                                    return;
                                  }
                                  try {
                                    int m = 0;
                                    int no = 0;
                                    int e = 0;
                                    int ni = 0;
                                    int qty = 0;
                                    if (_morningCount == null) {
                                      _morningCount = "0";
                                    }
                                    if (_noonCount == null) {
                                      _noonCount = "0";
                                    }
                                    if (_eveningCount == null) {
                                      _eveningCount = "0";
                                    }
                                    if (_nightCount == null) {
                                      _nightCount = "0";
                                    }
                                    qty = int.parse(_days) *
                                        (int.parse(_morningCount) +
                                            int.parse(_noonCount) +
                                            int.parse(_eveningCount) +
                                            int.parse(_nightCount));
                                    /* if (_morning == true) {
                                      qty = qty + int.parse(_days);
                                      m = 1;
                                    }
                                    if (_noon == true) {
                                      qty = qty + int.parse(_days);
                                      no = 1;
                                    }
                                    if (_evening == true) {
                                      qty = qty + int.parse(_days);
                                      e = 1;
                                    }
                                    if (_night == true) {
                                      qty = qty + int.parse(_days);
                                      ni = 1;
                                    }*/
                                    Map<String, dynamic> data = {
                                      "medicineName": _medicinename,
                                      "ProductId": _productId,
                                     /// "strength": _strength,
                                      "duration": _days,
                                      "quantity": qty,
                                      "morning": int.parse(_morningCount),
                                      "afterNoon": int.parse(_noonCount),
                                      "evening": int.parse(_eveningCount),
                                      "night": int.parse(_nightCount),
                                      "add": true
                                    };
                                    if (qty == 0) {
                                      _showSnackBar(
                                          "Select least one (Morning/Noon/Evening/Night) ");
                                    } else {
                                      try {
                                        widget.function(data);
                                        Navigator.pop(context);
                                      } catch (e) {
                                        _showSnackBar(e.toString());
                                      }
                                    }
                                  } catch (e) {
                                    _showSnackBar(e.toString());
                                  }
                                },
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Image.asset('assets/add.png'),
                                ),
                              ))
                          // _isLoading ? new CircularProgressIndicator() : SizedBox(height: 8.0),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  void _submit() {
    // deliveryName = deliveryToController.text.toString();
    // remarks = remarkController.text.toString();
  }

  void _showSnackBar(String text) {
    Fluttertoast.showToast(
      msg: text,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
    );
  }
}

class ConfirmOrderScreen extends StatefulWidget {
  // Declare a field that holds the Todo.
  List<Map<String, dynamic>> array = List();
  var orderType;

  // In the constructor, require a Todo.
  ConfirmOrderScreen(this.array, this.orderType);

  @override
  ConfirmOrderScreenState createState() => ConfirmOrderScreenState();
}

class ConfirmOrderScreenState extends State<ConfirmOrderScreen> {
  var yetToStartColor = const Color(0xFFF8A340);
  var blue = const Color(0xFF2188e5);
  String userId, token, surgeryName;
  var customerId;
  ProgressDialog progressDialog;
  bool _isLoading = false;
  final focusfsurgDeytail = FocusNode();
  final focuslsurgeNote = FocusNode();
  final focusDeliveryNote = FocusNode();
  TextEditingController surgeryDetailsController = TextEditingController();
  TextEditingController surgeryNoteController = TextEditingController();
  TextEditingController deliveryNoteController = TextEditingController();
  bool _requestPricscprion = false;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String _surgeDetail = "", _surgeNote = "", _deliveryNote = "";
  String filename = "";
  var requestPrescription = 0;
  final PermissionHandler _permissionHandler = PermissionHandler();

  // List<PermissionName> permissionNamesAndroid = [];
  // List<PermissionName> permissionNames = [];
  // PermissionName permissionName = PermissionName.Camera;

  bool cam = false, storage = false, record = false;
  File _imageFile;
  BuildContext cntx;
  bool isImageCaptured;
  final picker = ImagePicker();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    super.dispose();
  }

  void init() async {
    progressDialog = new ProgressDialog(cntx);
    progressDialog.style(
        message: "Please wait...",
        borderRadius: 4.0,
        backgroundColor: Colors.white);
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? "";
    userId = prefs.getString('userId') ?? "";
    customerId = prefs.getString('customerId') ?? "";
    fetchData();
    /* permissionNames.add(PermissionName.Camera);
    permissionNames.add(PermissionName.Storage);
    permissionNames.add(PermissionName.Microphone);

    permissionNames.add(PermissionName.Camera);
    permissionNames.add(PermissionName.Storage);
    permissionNames.add(PermissionName.Microphone);
    getPermissionsStatus();*/
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  Widget _buildImage() {
    if (_imageFile != null) {
      // return Image.file(_imageFile);
      return Expanded(
          child: Text(basename(_imageFile.path),
              style: TextStyle(fontSize: 15.0)));
    } else {
      return Text('', style: TextStyle(fontSize: 15.0));
    }
  }

  Future<void> captureImage(ImageSource imageSource) async {
    try {
      final imageFile = await picker.getImage(source: imageSource);
      setState(() {
        _imageFile = File(imageFile.path);
      });
    } catch (e) {
      print(e);
    }
  }

  Future camera() async {
    String filePath = await FileUtils.getDefaultFilePath();
    String uuid = DateTime.now().millisecondsSinceEpoch.toString();

    ///
    filePath = '$filePath/$uuid.png';

    List<CameraDescription> cameraDescription = await availableCameras();

    ////
    DarwinCameraResult result = await Navigator.push(
      cntx,
      MaterialPageRoute(
        builder: (context) => DarwinCamera(
          cameraDescription: cameraDescription,
          filePath: filePath,
          resolution: ResolutionPreset.high,
          defaultToFrontFacing: false,
          quality: 90,
        ),
      ),
    );

    ///
    ///
    if (result != null && result.isFileAvailable) {
      setState(() {
        isImageCaptured = true;
        _imageFile = result.file;
      });
      print(result.file);
      print(result.file.path);
    }
    //runApp(DarwinCameraTutorial());
  }

  void option() {
    showDialog(
        context: cntx,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)), //this right here
            child: Container(
              height: 300,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                          border: InputBorder.none, hintText: 'Select Options'),
                    ),
                    SizedBox(
                      width: 320.0,
                      child: RaisedButton(
                        onPressed: () {
                          if (storage != true) {
                            requestStoragePermission();
                          } else {
                            captureImage(ImageSource.gallery);
                            Navigator.pop(cntx);
                          }
                        },
                        child: Text(
                          "Gallery",
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(
                      width: 320.0,
                      child: RaisedButton(
                        onPressed: () {
                          if (cam != true) {
                            requestCameraPermission();
                          } else {
                            Navigator.pop(cntx);
                            camera();
                          }
                          //captureImage(ImageSource.camera);
                          /* Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MyAppCam()),
                          );*/
                        },
                        child: Text(
                          "Camera",
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width: 320.0,
                      child: FlatButton(
                        onPressed: () {
                          Navigator.pop(cntx);
                        },
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: Colors.grey),
                        ),
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  _requestCamPermission(PermissionGroup permission) async {
    try {
      var result = await _permissionHandler.requestPermissions([permission]);
      if (result[permission] == PermissionStatus.granted) {
        cam = true;
        return true;
      } else {
        cam = false;
        return false;
      }
    } catch (e) {
      _asyncConfirmDialog(e.toString());
    }
  }

  requestCameraPermission() async {
    return _requestCamPermission(PermissionGroup.camera);
  }

  _requestStoragePermission(PermissionGroup permission) async {
    try {
      var result = await _permissionHandler.requestPermissions([permission]);
      if (result[permission] == PermissionStatus.granted) {
        storage = true;
        return true;
      } else {
        storage = false;
        return false;
      }
    } catch (e) {
      _asyncConfirmDialog(e.toString());
    }
  }

  /// Requests the users permission to read their location when the app is in use
  requestStoragePermission() async {
    if (Platform.isIOS) {
      return _requestStoragePermission(PermissionGroup.photos);
    } else
      return _requestStoragePermission(PermissionGroup.storage);
  }

  @override
  Widget build(BuildContext context) {
    cntx = context;
    const gray = const Color(0xFFEEEFEE);
    double c_width = MediaQuery.of(context).size.width * 0.6;
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0.5,
          backgroundColor: Colors.white,
          brightness: Brightness.light,
          iconTheme: IconThemeData(
            color: Colors.black, //c// hange your color here
          ),
          centerTitle: true,
          title: const Text('ADD NEW MEDICINE',
              style: TextStyle(color: Colors.black)),
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context, true);
              }),
          // centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: new Column(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      SizedBox(height: 20),
                      new Padding(
                        padding: const EdgeInsets.all(10),
                        child: new Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            new Form(
                              key: formKey,
                              child: new Column(children: <Widget>[
                                widget.orderType == "3"
                                    ? Card(
                                        child: Column(
                                          children: <Widget>[
                                            new Padding(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child: FlatButton(
                                                  child: Row(
                                                    children: <Widget>[
                                                      Image.asset(
                                                        'assets/camera.png',
                                                        width: 30,
                                                        height: 30,
                                                      ),
                                                      SizedBox(
                                                        width: 2,
                                                      ),
                                                      Text(
                                                          "Upload Prescription",
                                                          style: TextStyle(
                                                              fontSize: 14))
                                                    ],
                                                  ),
                                                  onPressed: () {
                                                    try {
//                                                if (cam == false ||
//                                                    storage == false) )
                                                      /* else if (hasPermission(PermissionGroup.microphone) != true) {
                                                  requestMicPermission();
                                                }*/
                                                      if (storage != true) {
                                                        requestStoragePermission();
                                                      } else {
                                                        option();
                                                      }
                                                    } catch (e) {
                                                      //_asyncConfirmDialog(e.toString());
                                                    }
                                                  },
                                                )),
                                            new Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                children: <Widget>[
                                                  _buildImage()
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      )
                                    : SizedBox(
                                        height: 6,
                                      ),
                                SizedBox(
                                  height: 5,
                                ),
                                Card(
                                  child: Column(
                                    children: <Widget>[
                                      widget.orderType == "3"
                                          ? new Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 12),
                                              child: Row(
                                                children: <Widget>[
                                                  Checkbox(
                                                    onChanged: (bool value) {
                                                      setState(() {
                                                        _requestPricscprion =
                                                            value;
                                                      });
                                                    },
                                                    value: _requestPricscprion,
                                                  ),
                                                  Text("Request Prescription",
                                                      style: TextStyle(
                                                          fontSize: 14))
                                                ],
                                              ),
                                            )
                                          : SizedBox(
                                              height: 4,
                                            ),
                                      new Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Container(
                                            height: 50,
                                            child: new TextFormField(
                                              onSaved: (val) =>
                                                  _surgeDetail = val,
                                              validator: (val) {
                                                return val.trim().isEmpty
                                                    ? "Surgery Detail"
                                                    : null;
                                              },
                                              //initialValue: "",
                                              textInputAction:
                                                  TextInputAction.next,
                                              keyboardType: TextInputType.text,
                                              autofocus: false,
                                              controller:
                                                  surgeryDetailsController,
                                              onChanged: (_ctx) {
                                                if (surgeryDetailsController
                                                        .text !=
                                                    null)
                                                  _surgeDetail =
                                                      surgeryDetailsController
                                                          .text;
                                              },
                                              decoration: new InputDecoration(
                                                  labelText: "Surgery Detail",
                                                  border: new OutlineInputBorder(
                                                      borderRadius:
                                                          const BorderRadius
                                                                  .all(
                                                              const Radius
                                                                      .circular(
                                                                  5.0)))),
                                              onFieldSubmitted: (v) {
                                                FocusScope.of(context)
                                                    .requestFocus(
                                                        focusfsurgDeytail);
                                              },
                                            ),
                                          )),
                                      new Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Container(
                                            height: 50,
                                            child: new TextFormField(
                                              onSaved: (val) =>
                                                  _surgeNote = val,
                                              validator: (val) {
                                                return val.trim().isEmpty
                                                    ? "Surgery Note"
                                                    : null;
                                              },
                                              //initialValue: "",
                                              textInputAction:
                                                  TextInputAction.next,
                                              keyboardType: TextInputType.text,
                                              focusNode: focusfsurgDeytail,
                                              autofocus: false,
                                              controller: surgeryNoteController,
                                              onChanged: (_ctx) {
                                                if (surgeryNoteController
                                                        .text !=
                                                    null)
                                                  _surgeNote =
                                                      surgeryNoteController
                                                          .text;
                                              },
                                              decoration: new InputDecoration(
                                                  labelText: "Surgery Note",
                                                  border: new OutlineInputBorder(
                                                      borderRadius:
                                                          const BorderRadius
                                                                  .all(
                                                              const Radius
                                                                      .circular(
                                                                  5.0)))),
                                              onFieldSubmitted: (v) {
                                                FocusScope.of(context)
                                                    .requestFocus(
                                                        focuslsurgeNote);
                                              },
                                            ),
                                          )),
                                      new Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Container(
                                            height: 50,
                                            child: new TextFormField(
                                              onSaved: (val) =>
                                                  _deliveryNote = val,
                                              keyboardType: TextInputType.text,
                                              focusNode: focuslsurgeNote,
                                              validator: (val) {
                                                return val.trim().isEmpty
                                                    ? "Delivery Note"
                                                    : null;
                                              },
                                              controller:
                                                  deliveryNoteController,
                                              onChanged: (_ctx) {
                                                if (deliveryNoteController
                                                        .text !=
                                                    null)
                                                  _deliveryNote =
                                                      deliveryNoteController
                                                          .text;
                                              },
                                              //initialValue: "",
                                              decoration: new InputDecoration(
                                                  labelText: "Delivery Note",
                                                  border: new OutlineInputBorder(
                                                      borderRadius:
                                                          const BorderRadius
                                                                  .all(
                                                              const Radius
                                                                      .circular(
                                                                  5.0)))),
                                            ),
                                          )),
                                    ],
                                  ),
                                )
                              ]),
                            ),
                            new Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: new ButtonTheme(
                                    minWidth: 230,
                                    height: 45,
                                    child: !_isLoading
                                        ? new RaisedButton(
                                            onPressed: () {
                                              if (_surgeDetail == null) {
                                                _surgeDetail = "";
                                              }
                                              if (_surgeNote == null) {
                                                _surgeNote == "";
                                              }
                                              if (_deliveryNote == null) {
                                                _deliveryNote = "";
                                              }
                                              if (widget.orderType == "1" ||
                                                  widget.orderType == "2") {
                                                setState(() {
                                                  _isLoading = true;
                                                });
                                                placeorderApi();
                                              } else {
                                                if (_imageFile != null) {
                                                  setState(() {
                                                    _isLoading = true;
                                                  });
                                                  placeOrderWitOnlyPriscriptionApi();
                                                } else {
                                                  _showSnackBar(
                                                      "Upload Prescription");
                                                }
                                              }
                                            },
                                            child: new Text("Place Order"),
                                            color: yetToStartColor,
                                            textColor: Colors.white,
                                          )
                                        : SizedBox(
                                            width: 1,
                                          ))),
                            Padding(
                                padding: const EdgeInsets.all(4),
                                child: new Container(
                                    child: new Center(
                                  child: _isLoading
                                      ? new CircularProgressIndicator()
                                      : SizedBox(height: 8.0),
                                )))
                            // _isLoading ? new CircularProgressIndicator() : SizedBox(height: 8.0),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  void _submit() {
    // deliveryName = deliveryToController.text.toString();
    // remarks = remarkController.text.toString();
  }

  void fetchData() async {
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      "Content-type": "application/json",
      "Authorization": 'bearer $token'
    };

    final response =
        await http.get(RestDatasource.PROFILE_LIST_URL, headers: headers);
    setState(() {
      _isLoading = false;
    });
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, Object> data = json.decode(
          response.body); //orderType  orderStatusDesc  "orderDate"  orderId
      try {
        // if (data.containsKey("data")) {
        if (data == null) {
          _showSnackBar("No Data Found");
        } else {
          //profiledata = data;
          //print(data.toString());
          var status = data['status'];
          if (status != null && status == true) {
            setState(() {
              if (data['surgeryName'] != null) {
                surgeryName = data['surgeryName'].toString();
                surgeryDetailsController.text = surgeryName;
              }
            });
          } else {
            _showSnackBar("No Data Found");
          }
        }
      } catch (e) {
        _showSnackBar(e);
      }
    } else if (response.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('token');
      prefs.remove('userId');
      prefs.remove('name');
      prefs.remove('email');
      prefs.remove('mobile');
      Navigator.pushAndRemoveUntil(
          cntx,
          PageRouteBuilder(pageBuilder: (BuildContext context,
              Animation animation, Animation secondaryAnimation) {
            return LoginScreen();
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
      _showSnackBar('Session expired, Login again');
    } else {
      _showSnackBar('Something went wrong');
    }
  }

  void _asyncConfirmDialog(String mes) {
    showDialog<ConfirmAction>(
      context: cntx,
      barrierDismissible: false, // user must tap button for close dialog!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order Placed'),
          content: Text(mes),
          actions: <Widget>[
            FlatButton(
              child: const Text('Close'),
              onPressed: () async {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => Home(),
                    ),
                    ModalRoute.withName('/login_screen'));
              },
            )
          ],
        );
      },
    );
    // progressDialog.show();
  }

  void _showSnackBar(String text) {
    Fluttertoast.showToast(
      msg: text,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
    );
  }

  Future<Map<String, Object>> placeorderApi() async {
    if (_requestPricscprion == true) {
      requestPrescription = 1;
    }
    try {
      List<Map<String, dynamic>> arrayWithId = List();
      for (int i = 0; i < widget.array.length; i++) {
       /* Map<String, dynamic> map = {
          "medicineName": widget.array[i]["medicineName"],
          "strength": int.parse(widget.array[i]["strength"]),
          "duration": int.parse(widget.array[i]["duration"]),
          "quantity": widget.array[i]["quantity"],
          "morning": widget.array[i]["morning"],
          "afterNoon": widget.array[i]["afterNoon"],
          "evening": widget.array[i]["evening"],
          "night": widget.array[i]["night"],
          "orderDetailId": i + 1
        };*/
        Map<String, dynamic> map = {
          "medicineName": widget.array[i]["medicineName"],
          "duration": int.parse(widget.array[i]["duration"]),
          "quantity": widget.array[i]["quantity"],
          "morning": widget.array[i]["morning"],
          "afterNoon": widget.array[i]["afterNoon"],
          "evening": widget.array[i]["evening"],
          "night": widget.array[i]["night"],
          "orderDetailId": i + 1
        };
        arrayWithId.add(map);
      }
      Map<String, dynamic> dd = {
        "Items": arrayWithId,
        "RequestPrescription": requestPrescription,
        "CustomerId": int.parse(customerId),
        "SurgeryDetails": _surgeDetail,
        "DeliveryNote": _deliveryNote,
        "SurgeryNote": _surgeNote,
        "OrderTypeId": int.parse(widget.orderType)
      };
      final j = json.encode(dd);

      final JsonDecoder _decoder = new JsonDecoder();
      Map<String, String> headers = {
        "Content-type": "application/json",
        "Content-Type": "multipart/form-data",
        "Authorization": 'bearer $token'
      };

      /*  final response = await http.post(RestDatasource.PLACE_ORDER_LIST_URL,
           body: j,
           headers: headers);*/
      Uri uri = Uri.parse(RestDatasource.PLACE_ORDER_LIST_URL);
      http.MultipartRequest request = new http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      //request.fields['Items'] = arrayWithId.toString();
      request.fields['RequestPrescription'] = requestPrescription.toString();
      request.fields['CustomerId'] = customerId;
      request.fields['SurgeryDetails'] = _surgeDetail;
      request.fields['DeliveryNote'] = _deliveryNote;
      request.fields['SurgeryNote'] = _surgeNote;
      request.fields['OrderTypeId'] = widget.orderType;
      /* Map<String, dynamic> data = {
        "RequestPrescription": requestPrescription,
        "CustomerId": customerId,
        "SurgeryDetails": _surgeDetail,
        "DeliveryNote": _deliveryNote,
        "SurgeryNote": _surgeNote,
        "OrderTypeId": widget.orderType,
        widget.array[0]['medicineName']:  widget.array[0]["medicineName"].toString(),
        widget.array[0]['strength']:  widget.array[0]["strength"].toString(),
        widget.array[0]['duration']:  widget.array[0]["duration"].toString(),
        widget.array[0]['quantity']:  widget.array[0]["quantity"].toString(),
        widget.array[0]['morning']:  widget.array[0]["morning"].toString(),
        widget.array[0]['afterNoon']:  widget.array[0]["afterNoon"].toString(),
        widget.array[0]['evening']:  widget.array[0]["evening"].toString(),
        widget.array[0]['night']:  widget.array[0]["night"].toString(),
        widget.array[0]['orderDetailId']:  "0",
      };*/

      for (int i = 0; i < widget.array.length; i++) {
        request.fields["Items[$i][medicineName]"] =
            widget.array[i]["medicineName"].toString();
        request.fields["Items[$i][ProductId]"] =
            widget.array[i]["ProductId"].toString();
        request.fields["Items[$i][strength]"] =
            widget.array[i]["strength"].toString();
        request.fields["Items[$i][duration]"] =
            widget.array[i]["duration"].toString();
        request.fields["Items[$i][quantity]"] =
            widget.array[i]["quantity"].toString();
        request.fields["Items[$i][morning]"] =
            widget.array[i]["morning"].toString();
        request.fields["Items[$i][afterNoon]"] =
            widget.array[i]["afterNoon"].toString();
        request.fields["Items[$i][evening]"] =
            widget.array[i]["evening"].toString();
        request.fields["Items[$i][night]"] =
            widget.array[i]["night"].toString();
        request.fields["Items[$i][orderDetailId]"] = i.toString();
      }
      //final jj = json.encode(data);
      if (_imageFile != null) {
        request.files.add(
            await http.MultipartFile.fromPath('Prescription', _imageFile.path));
      }
      final http.StreamedResponse response = await request.send();
      print(response.statusCode);
      setState(() {
        _isLoading = false;
      });
      progressDialog.hide();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        Map data = json.decode(respStr);
        // If the server did return a 200 OK response,
        // then parse the JSON.
        // Map<String, Object> data = json.decode(response.body);
        //String data = response.toString();
        var status = data['status'];
        var message = data['message'];
        if (status == true) {
          var orderId = data['orderId'].toString();
          _asyncConfirmDialog(message);
        } else {
          _showSnackBar(message);
        }
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        prefs.remove('token');
        prefs.remove('userId');
        prefs.remove('name');
        prefs.remove('email');
        prefs.remove('mobile');
        Navigator.pushAndRemoveUntil(
            cntx,
            PageRouteBuilder(pageBuilder: (BuildContext context,
                Animation animation, Animation secondaryAnimation) {
              return LoginScreen();
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
        _showSnackBar('Session expired, Login again');
      } else {
        _showSnackBar('Something went wrong');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar(e.toString());
    }
  }

  Future<Map<String, Object>> placeOrderWitOnlyPriscriptionApi() async {
    int i = 0;
    if (_requestPricscprion == true) {
      i = 1;
    }
    try {
      final JsonDecoder _decoder = new JsonDecoder();
      Map<String, String> headers = {
        "Content-type": "application/json",
        "Content-Type": "multipart/form-data",
        "Authorization": 'bearer $token'
      };

      /*  final response = await http.post(RestDatasource.PLACE_ORDER_LIST_URL,
           body: j,
           headers: headers);*/
      Uri uri = Uri.parse(RestDatasource.PLACE_ORDER_LIST_URL);
      http.MultipartRequest request = new http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      //request.fields['Items'] = arrayWithId.toString();
      request.fields['RequestPrescription'] = i.toString();
      request.fields['CustomerId'] = customerId;
      request.fields['SurgeryDetails'] = _surgeDetail;
      request.fields['DeliveryNote'] = _deliveryNote;
      request.fields['SurgeryNote'] = _surgeNote;
      request.fields['OrderTypeId'] = widget.orderType;
      if (_imageFile != null) {
        request.files.add(
            await http.MultipartFile.fromPath('Prescription', _imageFile.path));
      }
      final http.StreamedResponse response = await request.send();
      print(response.statusCode);
      setState(() {
        _isLoading = false;
      });
      progressDialog.hide();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        Map data = json.decode(respStr);
        // If the server did return a 200 OK response,
        // then parse the JSON.
        // Map<String, Object> data = json.decode(response.body);
        //String data = response.toString();
        var status = data['status'];
        var message = data['message'];
        if (status == true) {
          var orderId = data['orderId'].toString();
          _asyncConfirmDialog(message);
        } else {
          _showSnackBar(message);
        }
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        prefs.remove('token');
        prefs.remove('userId');
        prefs.remove('name');
        prefs.remove('email');
        prefs.remove('mobile');
        Navigator.pushAndRemoveUntil(
            cntx,
            PageRouteBuilder(pageBuilder: (BuildContext context,
                Animation animation, Animation secondaryAnimation) {
              return LoginScreen();
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
        _showSnackBar('Session expired, Login again');
      } else {
        _showSnackBar('Something went wrong');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar(e.toString());
    }
  }
}

class MyImagePickerApp extends StatefulWidget {
  State<StatefulWidget> createState() {
    return new UserOptionsState();
  }
}

class UserOptionsState extends State<MyImagePickerApp> {
  //final ImagePicker _imagePicker = ImagePickerChannel();

  File _imageFile;

  Future<void> captureImage(ImageSource imageSource) async {
    try {
      final imageFile = await ImagePicker.pickImage(source: imageSource);
      setState(() {
        _imageFile = imageFile;
      });
    } catch (e) {
      print(e);
    }
  }

  Widget _buildImage() {
    if (_imageFile != null) {
      return Image.file(_imageFile);
    } else {
      return Text('Take an image to start', style: TextStyle(fontSize: 18.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("image picker"),
      ),
      body: Column(
        children: [
          Expanded(child: Center(child: _buildImage())),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return ConstrainedBox(
        constraints: BoxConstraints.expand(height: 80.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildActionButton(
                key: Key('retake'),
                text: 'Photos',
                onPressed: () => captureImage(ImageSource.gallery),
              ),
              _buildActionButton(
                key: Key('upload'),
                text: 'Camera',
                onPressed: () => captureImage(ImageSource.camera),
              ),
            ]));
  }

  Widget _buildActionButton({Key key, String text, Function onPressed}) {
    return Expanded(
      child: FlatButton(
          key: key,
          child: Text(text, style: TextStyle(fontSize: 20.0)),
          shape: RoundedRectangleBorder(),
          color: Colors.blueAccent,
          textColor: Colors.white,
          onPressed: onPressed),
    );
  }
}
