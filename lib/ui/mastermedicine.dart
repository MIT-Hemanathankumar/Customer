import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/data/rest_ds.dart';
import 'package:user/ui/login_screen.dart';
import 'package:user/ui/profile.dart';
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget {
  // In the constructor, require a Todo.

  final Function function;

  SearchPage({@required this.function});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool typing = false;
  String area = "";
  BuildContext _context;
  String lat, lan, city, pincode;
  List<dynamic> allList = new List();
  bool _isLoading = false;
  String userId, token;
  var yetToStartColor = const Color(0xFFF8A340);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //progressDialog = new ProgressDialog(cnxt);
    init();
  }

  void init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? "";
    userId = prefs.getString('userId') ?? "";
  }

  TextEditingController areaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    _context = context;
    double c_width = MediaQuery.of(context).size.width * 0.5;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'Add Medicine',
            style: TextStyle(color: Colors.black),
          ),
          iconTheme: IconThemeData(
            color: Colors.black, //c// hange your color here
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            Row(
              children: [
                _isLoading
                    ? Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: SizedBox(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation(Colors.black),
                          ),
                          height: 30.0,
                          width: 30.0,
                        ),
                      )
                    : SizedBox(height: 8.0)
              ],
            )
          ],
        ),
        body: SafeArea(
            child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 1.0, color: yetToStartColor),
                    ),
                    color: Colors.white,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter Medicine',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    controller: areaController,
                    cursorColor: Colors.black,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                    autofocus: true,
                    onChanged: (_ctx) {
                      if (areaController.text != null &&
                          areaController.text.length > 2) {
                        setState(() {
                          _isLoading = true;
                        });
                        searchArea(areaController.text);
                      }
                    },
                  ),
                )),
            new Expanded(
                child: ListView.builder(
                    padding: const EdgeInsets.all(0),
                    itemCount: allList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return new InkResponse(
                        onTap: () => _onTileClicked(index),
                        child: new Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom:
                                    BorderSide(width: 1.0, color: Colors.black),
                              ),
                              color: Colors.white,
                            ),
                            child: Column(
                              children: [
                                new Padding(
                                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                                  child: new Row(
                                    children: [
                                      Flexible(
                                          child: new Container(
                                        child: new Text(
                                          allList[index]['medicineName'],
                                          overflow: TextOverflow.ellipsis,
                                          //textAlign: TextAlign.left,
                                          //overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    })),
          ],
        )));
  }

  SliverList _getSlivers(List myList, BuildContext context, double c_width) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Visibility(
              visible: true,
              child: new InkResponse(
                onTap: () => _onTileClicked(index),
                child: new Padding(
                  padding: const EdgeInsets.only(
                      top: 1, bottom: 0, left: 3, right: 3),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(width: 1.0, color: Colors.black),
                      ),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        new Padding(
                          padding: const EdgeInsets.all(10),
                          child: new Row(
                            children: [
                              Flexible(
                                  child: new Container(
                                child: new Text(
                                  myList[index]['medicineName'],
                                  overflow: TextOverflow.ellipsis,
                                  //textAlign: TextAlign.left,
                                  //overflow: TextOverflow.ellipsis,
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ));
        },
        childCount: myList.length,
      ),
    );
  }

  void _onTileClicked(int index) {
    // showToast(allList[index]['officename'] + ', ' + allList[index]['districtname']);
    widget.function(allList[index]['medicineName'], allList[index]['productId']);
    Navigator.pop(context);
  }

  Future<Map<String, Object>> searchArea(String are) async {
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      'Content-type': 'application/json',
      "Authorization": 'bearer $token'
    };

    final response = await http.get(RestDatasource.MASTER_MEDICINE_URL + are,
        headers: headers);
    setState(() {
      _isLoading = false;
    });
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, Object> data = json.decode(response.body);
      //orderType  orderStatusDesc  "orderDate"  orderId
      try {
        // if (data.containsKey("data")) { medicineName,  productId
        if (data == null) {
          showToast("No Data Found");
        } else {
          print(data.toString());
          var status = data['status'];
          var uName = data['message'];
          if (status == true) {
            List<dynamic> homelist = data['list'];
            if (homelist.length > 0) {
              if (allList != null && allList.length > 0) {
                allList.clear();
              }
              setState(() {
                allList = homelist;
              });
            }
          }
        }
      } catch (e) {
        /// showToast(e);
      }
    } else if (response.statusCode == 401) {
      /* final prefs = await SharedPreferences.getInstance();
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
      showToast('Token expired, Login again');*/
      showToast('Something went wrong');
    } else {
      showToast('Something went wrong');
    }
  }

  void showToast(String mes) {
    Fluttertoast.showToast(
        msg: mes,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}
