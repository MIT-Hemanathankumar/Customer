import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/animations/fade_animation.dart';
import 'package:user/customview/cam/core/helper.dart';
import 'package:user/customview/cam/darwin_camera.dart';
import 'package:user/data/rest_ds.dart';
import 'package:user/database/moor_database.dart';
import 'package:user/database/moor_order_database.dart';
import 'package:user/enums/icon_enum.dart';
import 'package:user/model/Medicine.dart';
import 'package:user/model/OrderMedicine.dart';
import 'package:user/ui/camera.dart';
import 'package:user/ui/login_screen.dart';
import 'package:user/ui/main_page.dart';
import 'package:user/ui/profile.dart';
import 'package:http/http.dart' as http;
import 'package:user/ui/reminder/AddMedicine.dart';
import 'package:user/ui/reminder/AddOrderReminder.dart';
import 'package:user/ui/reminder/DeleteIcon.dart';
import 'package:user/ui/reminder/MedicineEmptyState.dart';
import 'package:user/ui/reminder/MedicineGridView.dart';
import 'package:user/ui/reminder/OrderDeleteIcon.dart';
import 'package:user/ui/reminder/OrderMedicineGridView.dart';

import '../data/AuthState.dart';
import '../data/DatabaseHelper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog/progress_dialog.dart';

class MyMedicine extends StatefulWidget {
  static String tag = 'place_order-screen';

  final bool showbackArrow;
  final bool orderReminder;

  MyMedicine(this.showbackArrow, this.orderReminder);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new MyMedicineState();
  }
}

class MyMedicineState extends State<MyMedicine> implements AuthStateListener {
  BuildContext _ctx;
  Future<File> imageFile;
  double opacity = 0.0;
  var yetToStartColor = const Color(0xFFF8A340);

  bool _isLoading = true;
  String userId, token;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String _medicinename, _strength, _days;
  final List<int> msgCount = <int>[2, 0, 10, 6, 52, 4, 0, 2];

  List<Map<String, dynamic>> array = List();

  ProgressDialog progressDialog;

  PlaceOrderState() {
    var authStateProvider = new AuthStateProvider();
    authStateProvider.subscribe(this);
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
                var strength = "";
                // if (homelist[i]['strength'] != null) {
                //strength = homelist[i]['strength'].toString();
                Map<String, dynamic> map = {
                  "medicineName": homelist[i]['medicineName'].toString(),
                  //"strength": strength.toString(),
                  "duration": "28",
                  "quantity": 7,
                  "morning": 1,
                  "afterNoon": 1,
                  "evening": 1,
                  "night": 1,
                  "add": false
                };
                array.add(map);
              }
              //}
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

  void _onTileClicked(int index) {
    if (widget.orderReminder == false) {
      Navigator.push(
        _ctx,
        MaterialPageRoute(
          builder: (context) => MyMedicineDetail(array: array[index]),
        ),
      );
    } else {
      Navigator.push(
        _ctx,
        MaterialPageRoute(
          builder: (context) => OrderReminderDetail(array: array[index]),
        ),
      );
    }
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

    const PrimaryColor = const Color(0xFFffffff);
    const titleColor = const Color(0xFF151026);
    return new Scaffold(
        appBar: AppBar(
          elevation: 0.5,
          centerTitle: true,
          title:
              const Text('MY MEDICINE', style: TextStyle(color: Colors.black)),
          backgroundColor: PrimaryColor,
          leading: widget.showbackArrow == true
              ? new Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context, false);
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.arrow_back),
                    ),
                  ))
              : SizedBox(
                  width: 1,
                ),
        ),
        key: scaffoldKey,
        body: SafeArea(
          child: Column(children: [
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
                      return GestureDetector(
                        onTap: () => _onTileClicked(index),
                        child: Container(
                            //height: 50,
                            margin: EdgeInsets.only(left: 4, right: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(0),
                              child: Card(
                                child: Row(
                                  children: <Widget>[
                                    SizedBox(
                                      width: 4,
                                    ),
                                    Expanded(
                                      child: Container(
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 4,
                                            ),
                                            Expanded(
                                                child: Column(
                                              children: [
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    array[index]["medicineName"]
                                                        .toString(),
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ))
                                          ],
                                        ),
                                      ),
                                      flex: 5,
                                    ),
                                    /* Expanded(
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
                                              array[index]["strength"]
                                                  .toString(),
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
                                              array[index]["duration"]
                                                  .toString(),
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black),
                                            )),
                                            CircleAvatar(
                                              backgroundColor: Colors.white,
                                              child: Icon(
                                                  Icons.keyboard_arrow_right),
                                            ),
                                          ],
                                        ),
                                      ),
                                      flex: 2,
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      );
                    })),
          ]),
        ));
  }
}

class MyMedicineDetail extends StatefulWidget {
  // Declare a field that holds the Todo.
  final Map<String, dynamic> array;

  // In the constructor, require a Todo.
  MyMedicineDetail({this.array});

  @override
  MyMedicineDetailState createState() => MyMedicineDetailState();
}

class MyMedicineDetailState extends State<MyMedicineDetail>
    implements AuthStateListener {
  BuildContext _ctx;
  Future<File> imageFile;
  double opacity = 0.0;
  var yetToStartColor = const Color(0xFFF8A340);

  bool _isLoading = true;
  String userId, token;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String _medicinename, _strength, _days;
  final List<int> msgCount = <int>[2, 0, 10, 6, 52, 4, 0, 2];

  List<Map<String, dynamic>> array = List();

  ProgressDialog progressDialog;

  PlaceOrderState() {
    var authStateProvider = new AuthStateProvider();
    authStateProvider.subscribe(this);
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
  }

  methodInParent(Map<String, dynamic> map) => {
        setState(() {
          array.add(map);
        })
      };

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    _ctx = context;
    progressDialog = new ProgressDialog(context);
    MedicineModel model;
    final deviceHeight = MediaQuery.of(context).size.height;

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

    const PrimaryColor = const Color(0xFFffffff);
    const titleColor = const Color(0xFF151026);
    return ScopedModel<MedicineModel>(
      model: model = MedicineModel(),
      child: Scaffold(
          appBar: AppBar(
            elevation: 0.5,
            centerTitle: true,
            title: Text(widget.array["medicineName"].toString(),
                style: TextStyle(color: Colors.black)),
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
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              buildBottomSheet(deviceHeight, model);
            },
            child: Icon(
              Icons.add,
              size: 40,
              color: Colors.white,
            ),
            backgroundColor: Theme.of(context).accentColor,
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Card(
                    child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: <Widget>[
                      /* Expanded(
                        child: Container(
                          child: Row(
                            children: [
                              Text(
                                "Strength",
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              SizedBox(
                                width: 4,
                              ),
                              Expanded(
                                  child: Text(
                                widget.array["strength"].toString(),
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                              ))
                            ],
                          ),
                        ),
                        flex: 1,
                      ),*/
                      Expanded(
                        child: Container(
                          child: Row(
                            children: [
                              Text(
                                "Days",
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              SizedBox(
                                width: 4,
                              ),
                              Expanded(
                                  child: Text(
                                widget.array["duration"].toString(),
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                              ))
                            ],
                          ),
                        ),
                        flex: 1,
                      ),
                    ],
                  ),
                )),
                SizedBox(
                  height: 10,
                ),
                //MyAppBar(greenColor: Theme.of(context).primaryColor),
                Expanded(
                  child: ScopedModelDescendant<MedicineModel>(
                    builder: (context, child, model) {
                      return Stack(children: <Widget>[
                        buildMedicinesView(model),
                        (model.getCurrentIconState() == DeleteIconState.hide)
                            ? Container()
                            : DeleteIcon()
                      ]);
                    },
                  ),
                )
              ],
            ),
          )),
    );
  }

  FutureBuilder buildMedicinesView(model) {
    return FutureBuilder(
      future: model.getMedicineList(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          print(snapshot.data);
          List<MedicinesTableData> array = List();
          if (snapshot.data.length == 0) {
            // No data
            return Center(child: MedicineEmptyState());
          }
          for (int i = 0; i < snapshot.data.length; i++) {
            MedicinesTableData data = snapshot.data[i];
            if (data.name.trim() ==
                widget.array['medicineName'].toString().trim()) {
              array.add(data);
            }
          }
          if (array.length == 0) {
            //No Data
            return Center(child: MedicineEmptyState());
          }
          return MedicineGridView(array);
        }
        return (Container());
      },
    );
  }

  void buildBottomSheet(double height, MedicineModel model) async {
    var medicineId = await showModalBottomSheet(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(45), topRight: Radius.circular(45))),
        context: _ctx,
        isScrollControlled: true,
        builder: (context) {
          return FadeAnimation(
            .6,
            AddMedicine(height, model.getDatabase(), model.notificationManager,
                widget.array['medicineName'].toString()),
          );
        });

    if (medicineId != null) {
      Fluttertoast.showToast(
          msg: "The Medicine was added!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIos: 1,
          backgroundColor: Theme.of(_ctx).accentColor,
          textColor: Colors.white,
          fontSize: 20.0);

      setState(() {});
    }
  }
}

class OrderReminderDetail extends StatefulWidget {
  // Declare a field that holds the Todo.
  final Map<String, dynamic> array;

  // In the constructor, require a Todo.
  OrderReminderDetail({this.array});

  @override
  OrderReminderDetailState createState() => OrderReminderDetailState();
}

class OrderReminderDetailState extends State<OrderReminderDetail>
    implements AuthStateListener {
  BuildContext _ctx;
  Future<File> imageFile;
  double opacity = 0.0;
  var yetToStartColor = const Color(0xFFF8A340);

  bool _isLoading = true;
  String userId, token;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String _medicinename, _strength, _days;
  final List<int> msgCount = <int>[2, 0, 10, 6, 52, 4, 0, 2];

  List<Map<String, dynamic>> array = List();

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
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? "";
    userId = prefs.getString('userId') ?? "";
  }

  methodInParent(Map<String, dynamic> map) => {
        setState(() {
          array.add(map);
        })
      };

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    _ctx = context;
    progressDialog = new ProgressDialog(context);
    OrderMedicineModel model;
    final deviceHeight = MediaQuery.of(context).size.height;

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

    const PrimaryColor = const Color(0xFFffffff);
    const titleColor = const Color(0xFF151026);
    return ScopedModel<OrderMedicineModel>(
      model: model = OrderMedicineModel(),
      child: Scaffold(
          appBar: AppBar(
            elevation: 0.5,
            centerTitle: true,
            title: Text(widget.array["medicineName"].toString(),
                style: TextStyle(color: Colors.black)),
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
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (widget.array["duration"] != null) {
                buildBottomSheet(deviceHeight, model, int.parse(widget.array["duration"].toString()));
              } else {
                _showSnackBar("Days not found for this medicine");
              }
            },
            child: Icon(
              Icons.add,
              size: 40,
              color: Colors.white,
            ),
            backgroundColor: Theme.of(context).accentColor,
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Card(
                    child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          child: Row(
                            children: [
                              Text(
                                "Days",
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              SizedBox(
                                width: 4,
                              ),
                              Expanded(
                                  child: Text(
                                widget.array["duration"].toString(),
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                              ))
                            ],
                          ),
                        ),
                        flex: 1,
                      ),
                    ],
                  ),
                )),
                SizedBox(
                  height: 10,
                ),
                //MyAppBar(greenColor: Theme.of(context).primaryColor),
                Expanded(
                  child: ScopedModelDescendant<OrderMedicineModel>(
                    builder: (context, child, model) {
                      return Stack(children: <Widget>[
                        buildMedicinesView(model),
                        (model.getCurrentIconState() == DeleteIconState.hide)
                            ? Container()
                            : OrderDeleteIcon()
                      ]);
                    },
                  ),
                )
              ],
            ),
          )),
    );
  }

  FutureBuilder buildMedicinesView(model) {
    return FutureBuilder(
      future: model.getMedicineList(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          print(snapshot.data);
          List<OrderMedicinesTableData> array = List();
          if (snapshot.data.length == 0) {
            // No data
            return Center(child: MedicineEmptyState());
          }
          for (int i = 0; i < snapshot.data.length; i++) {
            OrderMedicinesTableData data = snapshot.data[i];
            if (data.name.trim() ==
                widget.array['medicineName'].toString().trim()) {
              array.add(data);
            }
          }
          if (array.length == 0) {
            //No Data
            return Center(child: MedicineEmptyState());
          }
          return OrderMedicineGridView(array);
        }
        return (Container());
      },
    );
  }

  void buildBottomSheet(double height, OrderMedicineModel model,int time) async {
    var medicineId = await showModalBottomSheet(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(45), topRight: Radius.circular(45))),
        context: _ctx,
        isScrollControlled: true,
        builder: (context) {
          return FadeAnimation(
            .6,
            AddOrderReminder(
                height,
                model.getDatabase(),
                model.notificationManager,
                widget.array['medicineName'].toString(), time),
          );
        });

    if (medicineId != null) {
      Fluttertoast.showToast(
          msg: "The Reminder was added!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIos: 1,
          backgroundColor: Theme.of(_ctx).accentColor,
          textColor: Colors.white,
          fontSize: 20.0);

      setState(() {});
    }
  }
}
