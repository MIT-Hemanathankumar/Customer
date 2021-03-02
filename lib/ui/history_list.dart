import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:user/data/rest_ds.dart';
import 'package:user/presenter/delivery_list_presenter.dart';
import 'package:user/ui/login_screen.dart';
import 'package:user/ui/profile.dart';
import 'package:user/ui/splash_screen.dart';

class HistoryList extends StatefulWidget {
  final bool showBackarrow;

  HistoryList(this.showBackarrow);

  HistoryListState createState() => HistoryListState();
}

enum ConfirmAction { CANCEL, ACCEPT }

class HistoryListState extends State<HistoryList>
    implements DeliveryListCotract {
  BuildContext _ctx;
  bool _isLoading = true;
  bool hideList = true;
  String userId, token;
  final ScrollController _scrollController = ScrollController();
  DeliveryListPresenter _presenter;

  ProgressDialog progressDialog;
  var notdeliveryColor = const Color(0xFFE66363);
  var deliverColor = const Color(0xFF0071BC);
  var deliveredColor = const Color(0xFF4AC66E);
  var yetToStartColor = const Color(0xFFF8A340);

  // List<GroupModel> list = new List<GroupModel>();
  List<dynamic> allList = new List();
  List<dynamic> list = new List();
  var totalCount = 0;
  var completedCount = 0;
  var notDeliveredCount = 0;
  var yetToStartCount = 0;
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  String postalCode, address1, address2, townName;

  double _size = 1.0;

  void grow() {
    setState(() {
      _size += 0.1;
    });
  }

  void _onRefresh() async {
    // monitor network fetch
    //await Future.delayed(Duration(milliseconds: 1000));
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
    _presenter.doDeliveryList(userId, token);
  }

  void _onLoading() async {
    // monitor network fetch
    //await Future.delayed(Duration(milliseconds: 1000));
    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }

  HistoryListState() {
    _presenter = new DeliveryListPresenter(this);
    progressDialog = new ProgressDialog(context);
    progressDialog.style(
        message: "Please wait...",
        borderRadius: 4.0,
        backgroundColor: Colors.white);
    init();
  }

  void init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? "";
    userId = prefs.getString('userId') ?? "";
    progressDialog.show();
    fetchData();
    if (userId != null) fetchHistory();
  }

  /*methodInParent() => {
        if (userId != null) _presenter.doDeliveryList(userId, token)
        // Fluttertoast.showToast(msg: "Method called in parent", gravity: ToastGravity.CENTER)
      };*/

  @override
  void initState() {
    super.initState();
    // fetchData();
    //  _getUsers();
    // progressDialog.show();
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
  Widget build(BuildContext context) {
    const PrimaryColor = const Color(0xFFffffff);
    const gray = const Color(0xFFEEEFEE);
    const titleColor = const Color(0xFF151026);
    const blue = const Color(0xFF2188e5);
    double c_width = MediaQuery.of(context).size.width * 0.5;
    return Scaffold(
        backgroundColor: gray,
        appBar: AppBar(
          elevation: 0.5,
          centerTitle: true,
          title: const Text('History', style: TextStyle(color: Colors.black)),
          backgroundColor: PrimaryColor,
          leading: widget.showBackarrow == true
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
          actions: <Widget>[
            new Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Profile()));
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Image.asset('assets/dot.png'),
                  ),
                ))
          ],
        ),
        body: SafeArea(
          child: CustomScrollView(slivers: <Widget>[
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                    padding: const EdgeInsets.all(4),
                    child: new Container(
                        child: new Center(
                      child: _isLoading
                          ? new CircularProgressIndicator()
                          : SizedBox(height: 8.0),
                    )))
              ]),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.all(0),
                  child: new Container(
                      margin: EdgeInsets.symmetric(vertical: 1.0),
                      height: 50.0,
                      child: new ListView(
                        scrollDirection: Axis.vertical,
                        children: <Widget>[
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
                                      color: deliverColor,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Column(
                                      children: <Widget>[
                                        new Text(
                                          'Total',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white),
                                        ),
                                        new Text(
                                          totalCount.toString(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                          ),
                                        )
                                      ],
                                    )),
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
                                      color: yetToStartColor,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Column(
                                      children: <Widget>[
                                        new Text(
                                          'Yet to Start',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white),
                                        ),
                                        new Text(
                                          yetToStartCount.toString(),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white),
                                        ),
                                      ],
                                    )),
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
                                      color: deliveredColor,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Column(
                                      children: <Widget>[
                                        new Text(
                                          'Delivered',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white),
                                        ),
                                        new Text(
                                          completedCount.toString(),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white),
                                        ),
                                      ],
                                    )),
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
                                        color: notdeliveryColor,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          new Text(
                                            'Not delivered',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white),
                                          ),
                                          new Text(
                                            notDeliveredCount.toString(),
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white),
                                          ),
                                        ],
                                      )),
                                  flex: 1)
                            ],
                          )
                        ],
                      )),
                ),
              ]),
            ),
            _getSlivers(list, context, c_width)
          ]),
        ));
  }

  SliverList _getSlivers(List myList, BuildContext context, double c_width) {
    const blue = const Color(0xFF2188e5);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Visibility(
              visible: hideList,
              child: new InkResponse(
                onTap: () => _onTileClicked(index),
                child: new Padding(
                  padding: const EdgeInsets.only(
                      top: 1, bottom: 0, left: 3, right: 3),
                  child: new Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: new Row(
                        children: <Widget>[
                          new Expanded(
                            child: new Column(
                              children: [
                                new Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: new Row(
                                    children: [
                                      new Text(
                                        'Order Type ',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey),
                                      ),
                                      new Text(
                                        list[index]['orderType'],
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                                new Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: new Row(
                                    children: [
                                      new Text(
                                        'Status ', //orderDate
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey),
                                      ),
                                      /* Text(
                                  list[index]['address'],
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                  softWrap: true,
                                ),*/
                                      new Container(
                                        width: c_width,
                                        child: new Text(
                                          list[index]['orderStatusDesc'],
                                          //textAlign: TextAlign.left,
                                          //overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                new Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: new Row(
                                    children: [
                                      new Text(
                                        'Date ', //
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey),
                                      ),
                                      /* Text(
                                  list[index]['address'],
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                  softWrap: true,
                                ),*/
                                      new Container(
                                        width: c_width,
                                        child: new Text(
                                          list[index]['orderDate'],
                                          //textAlign: TextAlign.left,
                                          //overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            flex: 4,
                          ), //deliveryDate: 2020-03-05T00:00:00
                          new Expanded(
                            flex: 1,
                            child: new Column(
                              children: <Widget>[
                                if (list[index]['orderStatus'].toString() ==
                                        "1" ||
                                    list[index]['orderStatus'].toString() ==
                                        "2")
                                  new Container(
                                      //color: notdeliveryColor,
                                      margin: const EdgeInsets.all(3.0),
                                      padding: const EdgeInsets.all(3.0),
                                      decoration: BoxDecoration(
                                        color: yetToStartColor,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: new IconTheme(
                                          data: new IconThemeData(
                                              color: Colors.white),
                                          child: Image.asset(
                                            'assets/not_delivery.png',
                                            width: 50,
                                            height: 50,
                                          )))
                                else if (list[index]['deliveryStatus']
                                        .toString() ==
                                    "3")
                                  new Container(
                                      //color: notdeliveryColor,
                                      margin: const EdgeInsets.all(3.0),
                                      padding: const EdgeInsets.all(3.0),
                                      decoration: BoxDecoration(
                                        color: deliveredColor,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: new IconTheme(
                                          data: new IconThemeData(
                                              color: Colors.white),
                                          child: Image.asset(
                                            'assets/delivery_done.png',
                                            width: 50,
                                            height: 50,
                                          )))
                                else if (list[index]['orderStatus']
                                            .toString() ==
                                        "4" ||
                                    list[index]['orderStatus'].toString() ==
                                        "5")
                                  new Container(
                                      //color: notdeliveryColor,
                                      margin: const EdgeInsets.all(3.0),
                                      padding: const EdgeInsets.all(3.0),
                                      decoration: BoxDecoration(
                                        color: notdeliveryColor,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: new IconTheme(
                                          data: new IconThemeData(
                                              color: Colors.white),
                                          child: Image.asset(
                                            'assets/not_delivery.png',
                                            width: 50,
                                            height: 50,
                                          )))
                                else
                                  new Container(
                                      //color: notdeliveryColor,
                                      margin: const EdgeInsets.all(3.0),
                                      padding: const EdgeInsets.all(3.0),
                                      decoration: BoxDecoration(
                                        color: yetToStartColor,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: new IconTheme(
                                          data: new IconThemeData(
                                              color: Colors.white),
                                          child: Image.asset(
                                            'assets/not_delivery.png',
                                            width: 50,
                                            height: 50,
                                          )))
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ));
        },
        childCount: myList.length,
      ),
    );
  }

  void _todayFilter() {
    var now = new DateTime.now();
    var formatter = new DateFormat('yyyy-MM-dd');
    String formattedDate = formatter.format(now);
    //Fluttertoast.showToast(msg: formattedDate, toastLength: Toast.LENGTH_LONG);
    // list.clear();
    List<dynamic> listdd = new List();
    for (var i = 0; i < allList.length; i++) {
      print(allList[i]['deliveryDate'].toString());
      if (allList[i]['deliveryDate']
          .toString()
          .startsWith(formatter.format(now))) {
        listdd.add(allList[i]);
      }
    }
    if (listdd.length > 0) {
      setState(() {
        hideList = true;
        list = listdd;
        yetToStartCount = 0;
        notDeliveredCount = 0;
        completedCount = 0;
        totalCount = list.length;
        for (var i = 0; i < list.length; i++) {
          if (list[i]['orderStatus'].toString() == "1") {
            yetToStartCount++;
          } else if (list[i]['orderStatus'].toString() == "2") {
            yetToStartCount++;
          } else if (list[i]['orderStatus'].toString() == "3") {
            completedCount++;
          } else if (list[i]['orderStatus'].toString() == "4") {
            notDeliveredCount++;
          } else if (list[i]['orderStatus'].toString() == "5") {
            notDeliveredCount++;
          }
        }
      });
    } else {
      list = allList;
      setState(() {
        yetToStartCount = 0;
        notDeliveredCount = 0;
        completedCount = 0;
        totalCount = 0;
        hideList = false;
      });
      _showSnackBar("No data found on This date");
    }
  }

  void _datePicker() {
    var formatter = new DateFormat('yyyy-MM-dd');
    showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            //which date will display when user open the picker
            firstDate: DateTime(2020),
            //what will be the previous supported year in picker
            lastDate: DateTime(2050),
            builder: (BuildContext context, Widget child) {
              return Theme(
                data: ThemeData.light().copyWith(
                  primaryColor: yetToStartColor,
                  accentColor: yetToStartColor,
                  colorScheme: ColorScheme.light(primary: yetToStartColor),
                  buttonTheme:
                      ButtonThemeData(textTheme: ButtonTextTheme.primary),
                ),
                child: child,
              );
            }) //what will be the up to supported date in picker
        .then((pickedDate) {
      //then usually do the future job
      if (pickedDate == null) {
        //if user tap cancel then this function will stop
        return;
      }
      List<dynamic> listdd = new List();
      for (var i = 0; i < allList.length; i++) {
        print(allList[i]['deliveryDate'].toString());
        if (allList[i]['deliveryDate']
            .toString()
            .startsWith(formatter.format(pickedDate))) {
          listdd.add(allList[i]);
        }
      }
      if (listdd.length > 0) {
        setState(() {
          hideList = true;
          list = listdd;
          yetToStartCount = 0;
          notDeliveredCount = 0;
          completedCount = 0;
          totalCount = list.length;
          for (var i = 0; i < list.length; i++) {
            if (list[i]['orderStatus'].toString() == "1") {
              yetToStartCount++;
            } else if (list[i]['orderStatus'].toString() == "2") {
              yetToStartCount++;
            } else if (list[i]['orderStatus'].toString() == "3") {
              completedCount++;
            } else if (list[i]['orderStatus'].toString() == "4") {
              notDeliveredCount++;
            } else if (list[i]['orderStatus'].toString() == "5") {
              notDeliveredCount++;
            }
          }
        });
      } else {
        list = allList;
        setState(() {
          yetToStartCount = 0;
          notDeliveredCount = 0;
          completedCount = 0;
          totalCount = 0;
          hideList = false;
        });
        _showSnackBar("No data found on This date");
      }
    });
    /* DatePicker.showDatePicker(context,
        showTitleActions: true,
        minTime: DateTime(2018, 1, 1),
        maxTime: DateTime(2100, 12, 31), onChanged: (date) {
      // print('change $date');
    }, onConfirm: (date) {
      //Fluttertoast.showToast(msg: formatter.format(date), toastLength: Toast.LENGTH_LONG);
      //list.clear();
    }, currentTime: DateTime.now(), locale: LocaleType.en);*/
  }

  void _tomorrowFilter() {
    final now = DateTime.now();
    var formatter = new DateFormat('yyyy-MM-dd');
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    String formattedDate = formatter.format(tomorrow);
    // Fluttertoast.showToast(msg: formattedDate, toastLength: Toast.LENGTH_LONG);
    // list.clear();
    List<dynamic> listdd = new List();
    for (var i = 0; i < allList.length; i++) {
      print(allList[i]['deliveryDate'].toString());
      if (allList[i]['deliveryDate']
          .toString()
          .startsWith(formatter.format(tomorrow))) {
        listdd.add(allList[i]);
      }
    }
    if (listdd.length > 0) {
      setState(() {
        hideList = true;
        list = listdd;
        yetToStartCount = 0;
        notDeliveredCount = 0;
        completedCount = 0;
        totalCount = list.length;
        for (var i = 0; i < list.length; i++) {
          if (list[i]['orderStatus'].toString() == "1") {
            yetToStartCount++;
          } else if (list[i]['orderStatus'].toString() == "2") {
            yetToStartCount++;
          } else if (list[i]['orderStatus'].toString() == "3") {
            completedCount++;
          } else if (list[i]['orderStatus'].toString() == "4") {
            notDeliveredCount++;
          } else if (list[i]['orderStatus'].toString() == "5") {
            notDeliveredCount++;
          }
        }
      });
    } else {
      list = allList;
      setState(() {
        yetToStartCount = 0;
        notDeliveredCount = 0;
        completedCount = 0;
        totalCount = 0;
        hideList = false;
      });
      _showSnackBar("No data found on This date");
    }
  }

  void _empty() {}

  void _showSnackBar(String text) {
    Fluttertoast.showToast(
        msg: text,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER);
  }

  void _onTileClicked(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(todo: list[index],
            address:'$address1, $address2, $townName, $postalCode'),
      ),
    );
    //{orderId: 20, deliveryId: 3, customerName: Ramesh Thiru,
    // address: 123 Main Street,2nd Extension,Coimbatore,England,641041, deliveryNote: To home,
    // deliveryStatus: 0, deliveryDate: 2020-03-05T00:00:00}
    //new DetailScreen( notifyParent: refresh );
  }

  Future<Map<String, Object>> fetchHistory() async {
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      "Content-type": "application/json",
      "Authorization": 'bearer $token'
    };

    final response =
        await http.get(RestDatasource.ORDER_HISTORY_LIST_URL, headers: headers);
    setState(() {
      _isLoading = false;
    });
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, Object> data = json.decode(response.body);
      progressDialog.hide(); //orderType  orderStatusDesc  "orderDate"  orderId
      try {
        // if (data.containsKey("data")) {
        if (data == null) {
          _showSnackBar("No Data Found");
        } else {
          print(data.toString());
          List<dynamic> homelist = data['list'];
          final j = json.encode(data);
          if (homelist.length > 0) {
            setState(() {
              yetToStartCount = 0;
              notDeliveredCount = 0;
              completedCount = 0;
              list = homelist.reversed.toList();
              allList = homelist.reversed.toList();
              totalCount = list.length;
              hideList = true;
              /* for (var i = 0; i < list.length; i++) {
                  if (list[i]['orderStatus'].toString() == "1") {
                    yetToStartCount++;
                  } else if (list[i]['orderStatus'].toString() == "2") {
                    yetToStartCount++;
                  } else if (list[i]['orderStatus'].toString() == "3") {
                    completedCount++;
                  } else if (list[i]['orderStatus'].toString() == "4") {
                    notDeliveredCount++;
                  } else if (list[i]['orderStatus'].toString() == "5") {
                    notDeliveredCount++;
                  }
                }*/
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
          context,
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

  Future<Map<String, Object>> fetchData() async {
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
          _showSnackBar("No Data Found"); //address1, address2, townName
        } else {
          print(data.toString());
          var status = data['status'];
          if (status != null && status == true) {
            setState(() {
              if (data['postalCode'] != null)
                postalCode = data['postalCode'].toString();
              else
                postalCode = "";
              if (data['address1'] != null)
                address1 = data['address1'].toString();
              else
                address1 = "";
              if (data['address2'] != null)
                address2 = data['address2'].toString();
              else
                address2 = "";
              if (data['townName'] != null)
                townName = data['townName'].toString();
              else
                townName = "";
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
          context,
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

  @override
  void onDeliveryListError(String errorTxt) {
    progressDialog.hide();
    _showSnackBar(errorTxt);
  }

  @override
  Future<void> onDeliveryListSuccess(Map<String, Object> data) async {
    progressDialog.hide();
    setState(() => _isLoading = false);
    //_showSnackBar(data.toString());
    try {
      // if (data.containsKey("data")) {
      if (data == null) {
        _showSnackBar("No Data Found");
      } else {}
    } catch (e) {
      _showSnackBar(e);
    }
  }
}

// replace this function with the code in the examples
Widget _myListView(BuildContext context) {
  return ListView();
}

class OrderDetailScreen extends StatefulWidget {
  // Declare a field that holds the Todo.
  final Map<String, dynamic> todo;
  final String address;

  // In the constructor, require a Todo.
  OrderDetailScreen({this.todo, this.address});

  @override
  OrderDetailScreenState createState() => OrderDetailScreenState();
}

class OrderDetailScreenState extends State<OrderDetailScreen> {
  var yetToStartColor = const Color(0xFFF8A340);
  var blue = const Color(0xFF2188e5);
  String userId, token, customerId;
  ProgressDialog progressDialog;

  BuildContext cntx;
  bool isImageCaptured;
  List<dynamic> flowlist = new List();

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
    if (widget.todo['histories'] != null) {
      List<dynamic> list = new List();
      for (int i = 0; i < widget.todo['histories'].length; i++) {
        if (widget.todo['histories'][i]['status'] != null) {
          Map<String, dynamic> ma = widget.todo['histories'][i];
          setState(() {
            list.add(ma);
            flowlist = list;
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    init();
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
          title: const Text('VIEW MEDICINE DETAILS',
              style: TextStyle(color: Colors.black)),
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
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Profile()));
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Image.asset('assets/dot.png'),
                  ),
                ))
          ],
          // centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Card(
                        color: Color(0xFFC5FBC5),
                        child: Column(
                          children: <Widget>[
                            new Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Row(
                                          children: <Widget>[
                                            new Text(
                                              'Status',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey),
                                            ),
                                            SizedBox(
                                              width: 2,
                                            ),
                                            new Text(
                                              widget.todo["orderStatusDesc"]
                                                  .toString(),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black,
                                              ),
                                            )
                                          ],
                                        ),
                                        SizedBox(
                                          height: 8,
                                        ),
                                        Row(
                                          children: <Widget>[
                                            new Text(
                                              'Order ID',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey),
                                            ),
                                            SizedBox(
                                              width: 2,
                                            ),
                                            new Text(
                                              widget.todo["orderId"].toString(),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black,
                                              ),
                                            )
                                          ],
                                        ),
                                        SizedBox(
                                          height: 8,
                                        ),
                                        Row(
                                          children: <Widget>[
                                            new Text(
                                              'Delivery On',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey),
                                            ),
                                            SizedBox(
                                              width: 2,
                                            ),
                                            if (widget.todo["deliveryDate"] !=
                                                null)
                                              Flexible(
                                                  child: new Text(
                                                widget.todo["deliveryDate"]
                                                    .toString(),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black,
                                                ),
                                              ))
                                          ],
                                        )
                                      ],
                                    ),
                                    flex: 2,
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
                                      alignment: Alignment.centerRight,
                                      child: CircleAvatar(
                                        backgroundColor: Color(0xFFC5FBC5),
                                        child: Image.asset(
                                          'assets/tick.png',
                                          width: 70,
                                          height: 70,
                                        ),
                                      ),
                                    ),
                                    flex: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ]),
                ),
                if (widget.todo['items'] != null)
                  _getSlivers(widget.todo["items"], context, c_width),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 4, right: 4, top: 4, bottom: 15),
                      child: Card(
                        //color: Color(0xFFC5FBC5),
                        child: Column(
                          children: <Widget>[
                            new Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Row(
                                    children: <Widget>[
                                      new Text(
                                        'Status',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.grey),
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      new Text(
                                        widget.todo["orderStatusDesc"]
                                            .toString(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    height: 8,
                                  ),
                                  Row(
                                    children: <Widget>[
                                      new Text(
                                        'Order ID',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.grey),
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      new Text(
                                        widget.todo["orderId"].toString(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    height: 8,
                                  ),
                                  Row(
                                    children: <Widget>[
                                      new Text(
                                        'Order Date',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.grey),
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      if (widget.todo["orderDate"] != null)
                                        new Text(
                                          widget.todo["orderDate"].toString(),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.black,
                                          ),
                                        )
                                    ],
                                  ),
                                  SizedBox(
                                    height: 8,
                                  ),
                                  Row(
                                    children: <Widget>[
                                      new Text(
                                        'Shipping  Address',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.grey),
                                      ),
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
                                                      widget.address
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
                                  SizedBox(
                                    height: 4,
                                  ),
                                  Row(
                                    children: <Widget>[
                                      new Text(
                                        '',
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.grey),
                                      ),
                                      SizedBox(
                                        width: 2,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ]),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 4, right: 4, top: 10, bottom: 4),
                      //   child: Card(
                      //color: Color(0xFFC5FBC5),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              new Text(
                                'Order ID',
                                style:
                                    TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                              SizedBox(
                                width: 2,
                              ),
                              new Text(
                                widget.todo["orderId"].toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                      // ),
                    )
                  ]),
                ),
                if (flowlist != null && flowlist.length > 0)
                  _flow(flowlist, context, c_width),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 4, right: 4, top: 10, bottom: 10),
                      //   child: Card(
                      //color: Color(0xFFC5FBC5),
                      child: Column(
                        children: <Widget>[],
                      ),
                      // ),
                    )
                  ]),
                ),
              ],
            ),
          ),
        ));
  }

  SliverList _getSlivers(List myList, BuildContext context, double c_width) {
    const blue = const Color(0xFF2188e5);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Visibility(
              child: new InkResponse(
                  onTap: () => null,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Card(
                      child: Column(
                        children: <Widget>[
                          new Padding(
                            padding: const EdgeInsets.all(6),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: new Container(
                                      //color: deliverColor,
                                      margin: const EdgeInsets.all(3.0),
                                      padding: const EdgeInsets.all(0),
                                      child: Row(
                                        children: <Widget>[
                                          new Text(
                                            'Medicine',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey),
                                          ),
                                          SizedBox(
                                            width: 2,
                                          ),
                                          Expanded(
                                            child: new Text(
                                              widget.todo['items'][index]
                                                      ["medicineName"]
                                                  .toString(),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black,
                                              ),
                                            ),
                                          )
                                        ],
                                      )),
                                  flex: 1,
                                ),
                                /* Expanded(
                                  child: new Container(
                                      //color: deliverColor,
                                      margin: const EdgeInsets.all(3.0),
                                      padding: const EdgeInsets.all(0),
                                      child: Row(
                                        children: <Widget>[
                                          new Text(
                                            'Strength',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey),
                                          ),
                                          SizedBox(
                                            width: 2,
                                          ),
                                          new Text(
                                            widget.todo['items'][index]
                                                    ["strength"]
                                                .toString(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black,
                                            ),
                                          )
                                        ],
                                      )),
                                  flex: 1,
                                ),*/
                              ],
                            ),
                          ),
                          new Padding(
                            padding: const EdgeInsets.all(6),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: new Container(
                                      //color: deliverColor,
                                      margin: const EdgeInsets.all(3.0),
                                      padding: const EdgeInsets.all(0),
                                      child: Row(
                                        children: <Widget>[
                                          new Text(
                                            'No of days',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey),
                                          ),
                                          SizedBox(
                                            width: 4,
                                          ),
                                          widget.todo['items'][index]
                                                      ["duration"] !=
                                                  null
                                              ? Text(
                                                  widget.todo['items'][index]
                                                          ["duration"]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black,
                                                  ),
                                                )
                                              : Text("-")
                                        ],
                                      )),
                                  flex: 1,
                                ),
                                /* Expanded(
                                  child: new Container(
                                      //color: deliverColor,
                                      margin: const EdgeInsets.all(3.0),
                                      padding: const EdgeInsets.all(0),
                                      child: Row(
                                        children: <Widget>[
                                          new Text(
                                            'Remaining days',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey),
                                          ),
                                          SizedBox(
                                            width: 2,
                                          ),
                                          new Text(
                                            "",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black,
                                            ),
                                          )
                                        ],
                                      )),
                                  flex: 1,
                                ),*/
                              ],
                            ),
                          ),
                          new Padding(
                            padding: const EdgeInsets.all(6),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: new Container(
                                      //color: deliverColor,
                                      margin: const EdgeInsets.all(3.0),
                                      padding: const EdgeInsets.all(0),
                                      child: Row(
                                        children: <Widget>[
                                          new Text(
                                            'Order Type',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey),
                                          ),
                                          SizedBox(
                                            width: 2,
                                          ),
                                          new Text(
                                            "",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black,
                                            ),
                                          )
                                        ],
                                      )),
                                  flex: 1,
                                ),
                              ],
                            ),
                          ),
                          new Row(
                            children: <Widget>[
                              Expanded(
                                child: new Container(
                                  //color: deliverColor,
                                  margin: const EdgeInsets.all(3.0),
                                  padding: const EdgeInsets.only(
                                      left: 3.0, right: 3.0, bottom: 6.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      Checkbox(
                                        //title: Text("Night"),
                                        onChanged: (bool value) {},
                                        value: widget.todo['items'][index]
                                                    ["morning"] ==
                                                1
                                            ? true
                                            : false,
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
                                      left: 3.0, right: 3.0, bottom: 6.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      Checkbox(
                                        //title: Text("Night"),
                                        onChanged: (bool value) {},
                                        value: widget.todo['items'][index]
                                                    ["afterNoon"] ==
                                                1
                                            ? true
                                            : false,
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
                                      left: 3.0, right: 3.0, bottom: 6.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      Checkbox(
                                        //title: Text("Night"),
                                        onChanged: (bool value) {},
                                        value: widget.todo['items'][index]
                                                    ["evening"] ==
                                                1
                                            ? true
                                            : false,
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
                                        left: 3.0, right: 3.0, bottom: 6.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Column(
                                      children: <Widget>[
                                        Checkbox(
                                          //title: Text("Night"),
                                          onChanged: (bool value) {},
                                          value: widget.todo['items'][index]
                                                      ["night"] ==
                                                  1
                                              ? true
                                              : false,
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
                          ),
                        ],
                      ),
                    ),
                  )));
        },
        childCount: myList.length,
      ),
    );
  }

  SliverList _flow(List myList, BuildContext context, double c_width) {
    const blue = const Color(0xFF2188e5);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Visibility(
              child: new InkResponse(
                  onTap: () => null,
                  child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Container(
                          //height: 50,
                          margin: EdgeInsets.all(0),
                          child: Padding(
                              padding: const EdgeInsets.all(0),
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                          child: Row(
                                            children: [
                                              myList[index]["createdOn"]
                                                          .toString() !=
                                                      null
                                                  ? Icon(
                                                      Icons
                                                          .radio_button_checked,
                                                      color: Colors.green,
                                                    )
                                                  : Icon(
                                                      Icons
                                                          .radio_button_checked,
                                                      color: Colors.grey,
                                                    ),
                                              Expanded(
                                                  child: Text(
                                                myList[index]["status"]
                                                    .toString(),
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black),
                                              ))
                                            ],
                                          ),
                                        ),
                                        flex: 1,
                                      ),
                                      Expanded(
                                        child: Container(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                  child: Text(
                                                myList[index]["createdOn"]
                                                    .toString(),
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
                                  index + 1 != myList.length
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(left: 3),
                                          child: Container(
                                            height: 50,
                                            child: VerticalDivider(
                                                color: Colors.grey),
                                            alignment: Alignment.centerLeft,
                                          ),
                                        )
                                      : SizedBox()
                                ],
                              ))))));
        },
        childCount: myList.length,
      ),
    );
  }

  void _submit() {
    // deliveryName = deliveryToController.text.toString();
    // remarks = remarkController.text.toString();
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
              onPressed: () async {},
            )
          ],
        );
      },
    );
    // progressDialog.show();
  }

  void _showSnackBar(String text) {
    Fluttertoast.showToast(msg: text, toastLength: Toast.LENGTH_LONG);
  }
}
