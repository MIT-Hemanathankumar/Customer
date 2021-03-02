import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/customview/chat_bubble.dart';
import 'package:user/data/rest_ds.dart';
import 'package:http/http.dart' as http;
import 'package:user/ui/splash_screen.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool loader = true;
  TextEditingController _referralNameTc = new TextEditingController();
  bool nolist = false;
  BuildContext _context;
  ProgressDialog progressDialog;
  var cookie;
  List<dynamic> homeList = new List();
  int pageNo = 1;
  ScrollController _sc = new ScrollController();
  TextEditingController commentController = new TextEditingController();
  bool showSend = false;
  bool isLoading = false;
  String userId, token;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? "";
    userId = prefs.getString('userId') ?? "";

   /* List<dynamic> list = List();
    for (int index = 0; index < 6; index++) {
      Map<String, dynamic> map;
      if (index % 2 == 0) {
        map = {
          "name": "name a",
          "message": "message jjjjj " + index.toString(),
          "time": "date",
          "messageId": index,
          "userId": index.toString(),
        };
      } else {
        map = {
          "name": "name b",
          "message": "message aaaaaaaa " + index.toString(),
          "time": "date",
          "messageId": index,
          "userId": userId,
        };
      }
      list.add(map);
    }
    setState(() {
      homeList = list;
    });*/
    getChats();
    /* _sc.addListener(() {
      if (_sc.position.pixels == _sc.position.maxScrollExtent) {
        getChats();
      }
    });*/
  }

  @override
  void dispose() {
    _sc.dispose();
    //_videoController.dispose();
    super.dispose();
  }

  Future<Map<String, Object>> getChats() async {
    setState(() {
      isLoading = true;
    });
    Map<String, String> headers = {
      "Content-type": "application/json",
      "Authorization": 'bearer $token'
    };
    final response =
        await http.get(RestDatasource.PROFILE_LIST_URL, headers: headers);
    setState(() {
      isLoading = false;
    });
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, Object> data = json.decode(
          response.body); //orderType  orderStatusDesc  "orderDate"  orderId
      try {
        // if (data.containsKey("data")) {
        if (data == null) {
          print("No Data Found");
        } else {
          print(data.toString());
          var status = data['status'];
          var uName = data['message'];
          if (status == true) {
            List<dynamic> list = data['list'];
            if (list.length > 0) {
              if (homeList != null && homeList.length > 0) {
                homeList.clear();
              }
              setState(() {
                homeList = list;
              });
            }
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
          _context,
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
      _showSnackBar('Session expired, Login again');
    } else {
      _showSnackBar('Something went wrong');
    }
  }

  Future<Map<String, Object>> sendComment(String mes) async {
    progressDialog.show();
    Map<String, String> headers = {
      'Content-type': 'application/json',
      "Authorization": 'bearer $token'
    };

    final response =
        await http.get(RestDatasource.SEND_CHAT_URL + mes, headers: headers);
    progressDialog.hide();

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, Object> data = json.decode(response.body);
      var status = data['messageCode'];
      //orderType  orderStatusDesc  "orderDate"  orderId
      try {
        if (data == null) {
          print("No Data Found");
        } else {
          print(data.toString());
          var status = data['status'];
          var uName = data['message'];
          _showSnackBar(uName);
          if (status == true) {
           setState(() {
             commentController.text = '';
           });
          }
        }
      } catch (e) {
        _showSnackBar(e);
      }
    } else if (response.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('login');
      prefs.remove('cookie');
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
      _showSnackBar('Session expired, Login again');
    } else {
      progressDialog.hide();
      _showSnackBar('Something went wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    const PrimaryColor = const Color(0xFFffffff);
    progressDialog = new ProgressDialog(context);
    progressDialog.style(
        message: "Please wait...",
        borderRadius: 4.0,
        backgroundColor: Colors.white);
    return Scaffold(
        appBar: AppBar(
          elevation: 0.5,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Text('CHAT', style: TextStyle(color: Colors.grey)),
          // centerTitle: true,
        ),
        body: Container(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              SizedBox(
                height: 5.0,
              ),
              Expanded(
                  child: ListView.builder(
                itemCount: homeList.length,
                // Add one more item for progress indicator
                padding: EdgeInsets.symmetric(vertical: 8.0),
                itemBuilder: (BuildContext context, int index) {
                  /* return Container(
                   margin: const EdgeInsets.all(10),
                   child: Text( homeList[index]['name'].toString()),
                 );*/
                  return UI(
                    homeList[index]['name'].toString(),
                    homeList[index]['message'].toString(),
                    homeList[index]['time'].toString(),
                    homeList[index]['messageId'].toString(),
                    index,
                    homeList[index]['userId'].toString(),
                  );
                },
              )),
              Container(
                  height: 60.0,
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                      left: 10, right: 10, top: 5, bottom: 5),
                  //color: Colors.white,
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey[300],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(15))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                            padding: EdgeInsets.only(left: 10.0, right: 10.0),
                            child: Container(
                                child: Padding(
                              padding: const EdgeInsets.all(0),
                              child: TextFormField(
                                controller: commentController,
                                maxLines: 1,
                                onChanged: (context) {
                                  if (commentController.text != "") {
                                    setState(() {
                                      showSend = true;
                                    });
                                  } else {
                                    setState(() {
                                      showSend = false;
                                    });
                                  }
                                },
                                keyboardType: TextInputType.text,
                                style: TextStyle(
                                    fontFamily: "WorkSansSemiBold",
                                    fontSize: 16.0,
                                    color: Colors.black),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Type your message..",
                                  hintStyle: TextStyle(
                                      fontFamily: "WorkSansSemiBold",
                                      fontSize: 14.0),
                                ),
                              ),
                            ))),
                      ),
                      InkWell(
                        onTap: () {
                          if (commentController.text.trim() != '') {
                            sendComment(commentController.text);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Icon(
                            Icons.send,
                            color: showSend
                                ? Colors.deepOrangeAccent
                                : Colors.grey,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      )
                    ],
                  )),
            ],
          ),
        ));
  }

  Widget UI(String name, String message, String time, String mesgId, int index,
      String uId) {
    return new InkWell(
        onTap: () {},
        child: userId != uId
            ? Container(
                // height: 260,
                margin: EdgeInsets.fromLTRB(5.0, 10.0, 5.0, 5.0),
                child: Container(
                    padding: new EdgeInsets.only(
                        top: 10.0, bottom: 20.0, left: 0.0, right: 0.0),
                    child: new Column(children: <Widget>[
                      Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            CustomPaint(
                              painter: CustomChatBubble(isOwn: true,color: Colors.grey[200]),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5,right: 5,top: 8,bottom: 8),
                                child: Text(
                                  '$message',
                                  style: new TextStyle(color: Colors.black45),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {},
                              child: new Container(
                                width: 30.0,
                                height: 30.0,
                                //margin: EdgeInsets.only(top: 30.0),
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Image.asset('assets/profile_icon.png'),
                                ),
                              ),
                            ),
                          ])
                    ])))
            : Container(
                // height: 260,
                margin: EdgeInsets.fromLTRB(5.0, 10.0, 5.0, 5.0),
                child: Container(
                    padding: new EdgeInsets.only(
                        top: 10.0, bottom: 20.0, left: 0.0, right: 0.0),
                    child: new Column(children: <Widget>[
                      Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            InkWell(
                              onTap: () {},
                              child: new Container(
                                width: 30.0,
                                height: 30.0,
                                //margin: EdgeInsets.only(top: 30.0),
                                child: CircleAvatar(
                                  child: Image.asset('assets/app_icon.png'),
                                ),
                              ),
                            ),
                            CustomPaint(
                              painter: CustomChatBubble(isOwn: false, color: Colors.red[100]),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5,right: 5,top: 8,bottom: 8),
                                child: Text(
                                  '$message',
                                  style: new TextStyle(color: Colors.black45),
                                ),
                              ),
                            ),
                          ])
                    ]))));
  }

  void _showSnackBar(String text) {
    Fluttertoast.showToast(
        msg: text,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_LONG);
  }
}
