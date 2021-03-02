import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user/data/rest_ds.dart';
import 'package:user/ui/chatscreen.dart';
import 'package:user/ui/emptyscreen.dart';
import 'package:user/ui/history_list.dart';
import 'dart:ui' as ui;

import 'package:user/ui/login_screen.dart';
import 'package:user/ui/my_medicine.dart';
import 'package:user/ui/order_now_main.dart';
import 'package:user/ui/permission.dart';
import 'package:user/ui/profile.dart';
import 'package:user/util/local_notification.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomeState();
  }
}

enum ConfirmAction { CANCEL, ACCEPT }

final scaffoldKey = new GlobalKey<ScaffoldState>();

class Logic {
  void doSomething() {
    final BottomNavigationBar navigationBar = scaffoldKey.currentWidget;
    navigationBar.onTap(1);
  }
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  var blue = const Color(0xFF0071BC);
  BuildContext _context;
  String userId, token;
  ProgressDialog progressDialog;
  String isApproved;
  String pharmacyContactNo, branchContactNo;

  final List<Widget> _children = [
    HomeWidget(),
    OrderOption(false),
    MyMedicine(false, false),
    EmptyApp(false),
    ChatPage()
  ];

  void init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? "";
    userId = prefs.getString('userId') ?? "";
    fetchData();
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  _launchCallURL(String url) async {
    final Uri bugMail = Uri(scheme: 'tel', path: url);
    if (await canLaunch(bugMail.toString())) {
      await launch(bugMail.toString());
    } else {
      _showSnackBar('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    progressDialog = new ProgressDialog(context);
    progressDialog.style(
        message: "Please wait...",
        borderRadius: 4.0,
        backgroundColor: Colors.white);

    return new WillPopScope(
        child: Scaffold(
          appBar: null,
          body: _children[_currentIndex],
          bottomNavigationBar: Theme(
            data: Theme.of(context).copyWith(
              // sets the background color of the `BottomNavigationBar`
              canvasColor: Colors.white,
              // sets the active color of the `BottomNavigationBar` if `Brightness` is light
              primaryColor: Color(0xfff58053),
            ),
            key: scaffoldKey,
            child: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: ImageIcon(
                    AssetImage("assets/home.png"),
                    color: Colors.grey,
                  ),
                  title: Text(''),
                  activeIcon: ImageIcon(
                    AssetImage("assets/home.png"),
                    color: Color(0xfff58053),
                  ),
                ),
                BottomNavigationBarItem(
                  icon: ImageIcon(
                    AssetImage("assets/place_order.png"),
                    color: Colors.grey,
                  ),
                  title: Text(''),
                  activeIcon: ImageIcon(
                    AssetImage("assets/place_order.png"),
                    color: Color(0xfff58053),
                  ),
                ),
                BottomNavigationBarItem(
                  icon: ImageIcon(
                    AssetImage("assets/history_icon.png"),
                    color: Colors.grey,
                  ),
                  title: Text(''),
                  activeIcon: ImageIcon(
                    AssetImage("assets/history_icon.png"),
                    color: Color(0xfff58053),
                  ),
                ),
                BottomNavigationBarItem(
                  icon: ImageIcon(
                    AssetImage("assets/call.png"),
                    color: Colors.grey,
                  ),
                  title: Text(''),
                  activeIcon: ImageIcon(
                    AssetImage("assets/call.png"),
                    color: Color(0xfff58053),
                  ),
                ),
                BottomNavigationBarItem(
                  icon: ImageIcon(
                    AssetImage("assets/chat.png"),
                    color: Colors.grey,
                  ),
                  title: Text(''),
                  activeIcon: ImageIcon(
                    AssetImage("assets/chat.png"),
                    color: Color(0xfff58053),
                  ),
                ),
              ],
              currentIndex: _currentIndex,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white30,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              onTap: onTabTapped,
              //key: globalKey,
            ),
          ),
        ),
        onWillPop: _onWillPop);
  }

  Future<Map<String, Object>> fetchData() async {
    //progressDialog.show();
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      "Content-type": "application/json",
      "Authorization": 'bearer $token'
    };

    final response =
        await http.get(RestDatasource.PROFILE_LIST_URL, headers: headers);
    //progressDialog.hide();
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, Object> data = json.decode(
          response.body); //orderType  orderStatusDesc  "orderDate"  orderId
      try {
        // if (data.containsKey("data")) {pharmacyId, branchId
        if (data == null) {
          _showSnackBar("No Data Found");
        } else {
          print(data.toString());
          var status = data['status'];
          isApproved = data['isApproved'].toString();
          branchContactNo = data['branchContactNo'].toString();
          pharmacyContactNo = data['pharmacyContactNo'].toString();
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
          _context,
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

  void _accountStatusDialog(String mes) {
    showDialog<ConfirmAction>(
      context: _context,
      barrierDismissible: true, // user must tap button for close dialog!
      builder: (BuildContext context) {
        return AlertDialog(
          //title: Text('Profile Update'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 10,
              ),
              RichText(
                text: new TextSpan(
                  // Note: Styles for TextSpans must be explicitly defined.
                  // Child text spans will inherit styles from parent
                  style: new TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    new TextSpan(text: mes),
                  ],
                ),
              ),
              SizedBox(
                width: 20,
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(''),
                    RaisedButton(
                      color: Colors.orange,
                      textColor: Colors.white,
                      child: Text('Close'),
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                    ),
                  ])
            ],
          ),
        );
      },
    );
    // progressDialog.show();
  }

  void onTabTapped(int index) {
    if (index == 3) {
      if (branchContactNo != null) {
        _showSnackBar("Please wait...");
        _launchCallURL(branchContactNo);
      } else {
        _showSnackBar("Contact Not Found, try Later");
      }
    } else if (index == 1) {
      if (isApproved != null) {
        if (isApproved == '1') {
          setState(() {
            _currentIndex = index;
          });
        } else if (isApproved == '2') {
          _accountStatusDialog(
              "Your profile is not approved , kindly contact branch admin");
        } else {
          _accountStatusDialog(
              "Your profile is pending approval, You will be able to create an order after it is approved");
        }
      } else {
        setState(() {
          _currentIndex = index;
        });
      }
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: _context,
          builder: (context) => new AlertDialog(
            title: new Text('Are you sure?'),
            content: new Text('Do you want to exit an App'),
            actions: <Widget>[
              new FlatButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: new Text('No'),
              ),
              new FlatButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: new Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }
}

class HomeWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeWidgetState();
  }
}

class Item {
  Item({this.itemId});

  final String itemId;

  StreamController<Item> _controller = StreamController<Item>.broadcast();

  Stream<Item> get onChanged => _controller.stream;

  String _status;

  String get status => _status;

  set status(String value) {
    _status = value;
    _controller.add(this);
  }

  static final Map<String, Route<void>> routes = <String, Route<void>>{};

  Route<void> get route {
    final String routeName = '/detail/$itemId';
    return routes.putIfAbsent(
      routeName,
      () => MaterialPageRoute<void>(
        settings: RouteSettings(name: routeName),
        builder: (BuildContext context) => Home(),
      ),
    );
  }
}

class HomeWidgetState extends State<HomeWidget> {
  int _currentIndex = 0;
  BuildContext _ctx;
  bool isHome = true;
  Color _homeIconColor = Colors.grey;
  var yetToStartColor = const Color(0xfff58053);
  var blue = const Color(0xFF0071BC);
  final Map<String, Item> _items = <String, Item>{};
  String userId, authtoken, customerId;
  String _homeScreenText = "Waiting for token...";
  bool _topicButtonsDisabled = false;
  String isApproved;
  ProgressDialog progressDialog;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final TextEditingController _topicController =
      TextEditingController(text: 'topic');

  Widget _buildDialog(BuildContext context, String item) {
    return AlertDialog(
      content: Text(item.toString()),
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

  void _showItemDialog(Map<String, dynamic> message) {
    showDialog<bool>(
      context: _ctx,
      builder: (_) =>
          _buildDialog(_ctx, message['notification']['body'].toString()),
    ).then((bool shouldNavigate) {
      /* if (shouldNavigate == true) {
        _navigateToItemDetail(message);
      }*/
    });
  }

  final List<Widget> _children = [
    Home(),
    OrderOption(false),
    HistoryList(false),
    HistoryList(false),
    HistoryList(false)
  ];

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    authtoken = prefs.getString('token') ?? "";
    userId = prefs.getString('userId') ?? "";
    customerId = prefs.getString('customerId') ?? "";
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        _showItemDialog(message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        // _navigateToItemDetail(message);
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        // _navigateToItemDetail(message);
      },
    );

    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(
            sound: true, badge: true, alert: true, provisional: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      setState(() {
        _homeScreenText = "Push Messaging token: $token";
      });
      print(_homeScreenText);
      if (token != null) {
        fetchData(token);
      }
    });
  }

  Future<Map<String, Object>> fetchData(String token) async {
    progressDialog.show();
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      "Content-type": "application/json",
      "Authorization": 'bearer $authtoken'
    };

    final response =
        await http.get(RestDatasource.PROFILE_LIST_URL, headers: headers);
    progressDialog.hide();
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, Object> data = json.decode(
          response.body); //orderType  orderStatusDesc  "orderDate"  orderId
      try {
        // if (data.containsKey("data")) {pharmacyId, branchId
        if (data == null) {
          _showSnackBar("No Data Found");
        } else {
          print(data.toString());
          var status = data['status'];
          isApproved = data['isApproved'].toString();
          if (status != null && status == true) {
            if (data['pharmacyId'] != null && data['branchId'] != null)
              updateApi(data['pharmacyId'].toString(),
                  data['branchId'].toString(), token);
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
      _showSnackBar('Session expired, Login again');
    } else {
      _showSnackBar('Something went wrong');
    }
  }

  void _accountStatusDialog(String mes) {
    showDialog<ConfirmAction>(
      context: _ctx,
      barrierDismissible: true, // user must tap button for close dialog!
      builder: (BuildContext context) {
        return AlertDialog(
          //title: Text('Profile Update'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 10,
              ),
              RichText(
                text: new TextSpan(
                  // Note: Styles for TextSpans must be explicitly defined.
                  // Child text spans will inherit styles from parent
                  style: new TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    new TextSpan(text: mes),
                  ],
                ),
              ),
              SizedBox(
                width: 20,
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(''),
                    RaisedButton(
                      color: Colors.orange,
                      textColor: Colors.white,
                      child: Text('Close'),
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                    ),
                  ])
            ],
          ),
        );
      },
    );
    // progressDialog.show();
  }

  Future<Map<String, Object>> updateApi(
      String pharmacyId, String branchId, String token) async {
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      "Content-type": "application/json",
      "Authorization": 'bearer $authtoken'
    };
    Map<String, dynamic> map = {
      "pharmacyId": int.parse(pharmacyId),
      "userId": int.parse(userId),
      "tokenId": token,
      "branchId": int.parse(branchId),
      "message": "token register done"
    };
    final j = json.encode(map);
    final response = await http.post(RestDatasource.SEND_TOKEN_URL,
        body: j, headers: headers);
    final String res = response.body;
    final int statusCode = response.statusCode;
    if (response.statusCode == 200) {
      Map<String, Object> data = json.decode(response.body);
      if (data != null) {
        var status = data['status'];
        var uName = data['message'];
        //_showSnackBar(uName);
      }
    } else if (response.statusCode == 401) {
      //_showSnackBar('Session expired, try again');
    } else {
      //_showSnackBar('Something went wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    _ctx = context;
    progressDialog = new ProgressDialog(context);
    progressDialog.style(
        message: "Please wait...",
        borderRadius: 4.0,
        backgroundColor: Colors.white);

    var logo = new Column(
      children: <Widget>[
        new SizedBox(
          child: Image.asset(
            'assets/place_order.png',
            fit: BoxFit.fill,
          ),
        )
      ],
    );

    var logo2 = new Column(
      children: <Widget>[
        new SizedBox(
          child: Image.asset(
            'assets/history_white.png',
            fit: BoxFit.fill,
          ),
        )
      ],
    );
    var logo3 = new Column(
      children: <Widget>[
        new SizedBox(
          child: Image.asset(
            'assets/location_white.png',
            fit: BoxFit.fill,
          ),
        )
      ],
    );
    var logo4 = new Column(
      children: <Widget>[
        new SizedBox(
          child: Image.asset(
            'assets/report_white.png',
            fit: BoxFit.fill,
          ),
        )
      ],
    );

    var deliveryItem = new GestureDetector(
        onTap: () {
          if (isApproved != null) {
            if (isApproved == '1') {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => OrderOption(true)));
            } else if (isApproved == '2') {
              _accountStatusDialog(
                  "Your profile is not approved , kindly contact branch admin");
            } else {
              _accountStatusDialog(
                  "Your profile is pending approval, You will be able to create an order after it is approved");
            }
          } else {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => OrderOption(true)));
          }
        },
        child: new Container(
          margin: const EdgeInsets.only(
              left: 10.0, top: 10.0, right: 10.0, bottom: 10.0),
          child: new DecoratedBox(
              decoration: const BoxDecoration(
                  color: const Color(0xfff58053),
                  borderRadius:
                      const BorderRadius.all(const Radius.circular(5.0))),
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  logo,
                  new Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: new Text("Place Your Order",
                          style: new TextStyle(
                            fontSize: 8.0,
                            color: Colors.white,
                          ),
                          textScaleFactor: 2.0,
                          textAlign: TextAlign.center)),
                  // _isLoading ? new CircularProgressIndicator() : SizedBox(height: 8.0),
                ],
              )),
        ));
    var historyItem = new GestureDetector(
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => HistoryList(true)));
        },
        child: new Container(
          margin: const EdgeInsets.only(
              left: 10.0, top: 10.0, right: 10.0, bottom: 10.0),
          child: new DecoratedBox(
              decoration: const BoxDecoration(
                  color: const Color(0xfffac536),
                  borderRadius:
                      const BorderRadius.all(const Radius.circular(5.0))),
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  logo2,
                  new Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: new Text("History",
                          style: new TextStyle(
                            fontSize: 8.0,
                            color: Colors.white,
                          ),
                          textScaleFactor: 2.0,
                          textAlign: TextAlign.center)),
                  // _isLoading ? new CircularProgressIndicator() : SizedBox(height: 8.0),
                ],
              )),
        ));
    var mapItem = new GestureDetector(
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => EmptyApp(true)));
        },
        child: new Container(
          margin: const EdgeInsets.only(
              left: 10.0, top: 10.0, right: 10.0, bottom: 10.0),
          child: new DecoratedBox(
              decoration: const BoxDecoration(
                  color: const Color(0xff6d33f1),
                  borderRadius:
                      const BorderRadius.all(const Radius.circular(5.0))),
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  logo3,
                  new Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: new Text("Track Your Order",
                          style: new TextStyle(
                            fontSize: 8.0,
                            color: Colors.white,
                          ),
                          textScaleFactor: 2.0,
                          textAlign: TextAlign.center)),
                  // _isLoading ? new CircularProgressIndicator() : SizedBox(height: 8.0),
                ],
              )),
        ));
    var reportItem = new GestureDetector(
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => EmptyApp(true)));
        },
        child: new Container(
          margin: const EdgeInsets.only(
              left: 10.0, top: 10.0, right: 10.0, bottom: 10.0),
          child: new DecoratedBox(
              decoration: const BoxDecoration(
                  color: const Color(0xff39c073),
                  borderRadius:
                      const BorderRadius.all(const Radius.circular(5.0))),
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  logo4,
                  new Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: new Text("Reports",
                          style: new TextStyle(
                            fontSize: 8.0,
                            color: Colors.white,
                          ),
                          textScaleFactor: 2.0,
                          textAlign: TextAlign.center)),
                  // _isLoading ? new CircularProgressIndicator() : SizedBox(height: 8.0),
                ],
              )),
        ));

    const PrimaryColor = const Color(0xFFffffff);
    const titleColor = const Color(0xFF151026);
    return new WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            elevation: 0.5,
            centerTitle: true,
            title: const Text('Home', style: TextStyle(color: Colors.black)),
            backgroundColor: PrimaryColor,
            leading: new Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Profile()));
                    /* Navigator.push(context,
                        MaterialPageRoute(builder: (context) => HomeNotifyPage()));*/
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Image.asset('assets/dot.png'),
                  ),
                )),
          ),
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
                            crossAxisCount: 2,
                            children: <Widget>[
                              deliveryItem,
                              historyItem,
                              mapItem,
                              reportItem,
                            ],
                          )))),
              new Text(''),
            ]),
          ),
        ),
        onWillPop: _onWillPop);
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: _ctx,
          builder: (context) => new AlertDialog(
            title: new Text('Are you sure?'),
            content: new Text('Do you want to exit an App'),
            actions: <Widget>[
              new FlatButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: new Text('No'),
              ),
              new FlatButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: new Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }
}

Future<bool> _onBackPressed() async {
  // Your back press code here...
  _showSnackBar("onbackpress");
}

void _showSnackBar(String text) {
  Fluttertoast.showToast(msg: text, toastLength: Toast.LENGTH_LONG);
}
