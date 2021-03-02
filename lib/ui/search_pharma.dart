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

class SearchPharma extends StatefulWidget {
  // In the constructor, require a Todo.

  final Function function;

  SearchPharma({@required this.function});

  @override
  _SearchPharmaState createState() => _SearchPharmaState();
}

class _SearchPharmaState extends State<SearchPharma> {
  bool typing = false;
  String area = "";
  BuildContext _context;
  String lat, lan, city, pincode;
  bool _isLoading = false;
  String userId, token;
  var yetToStartColor = const Color(0xFFF8A340);
  List menuItems = List();
  String _mySelection, pharmacyrid, branchId;
  List pharmacyIdList = List();
  List branchIdList = List();
  List pincodeList = List();

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
    searchArea("");
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
            'Search Pharmacy',
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
                      hintText: 'Enter Postal Code or Pharmacy',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    controller: areaController,
                    cursorColor: Colors.black,
                    textCapitalization: TextCapitalization.characters,
                    keyboardType: TextInputType.text,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                    autofocus: true,
                    onChanged: (_ctx) {
                      if (areaController.text != null &&
                          areaController.text.length >= 2) {
                        setState(() {
                          _isLoading = true;
                        });
                        searchArea(areaController.text);
                      }else{
                        searchArea("");
                      }
                    },
                  ),
                )),
            new Expanded(
                child: ListView.builder(
                    padding: const EdgeInsets.all(0),
                    itemCount: menuItems.length,
                    itemBuilder: (BuildContext context, int index) {
                      return new InkResponse(
                        onTap: () => _onTileClicked(index),
                        child: new Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom:
                                    BorderSide(width: 0.5, color: Colors.grey),
                              ),
                              color: Colors.white,
                            ),
                            child:  Padding(
                              padding: const EdgeInsets.only(left: 10, right: 10, top: 15,bottom: 15),
                              child: RichText(
                                text: new TextSpan(
                                  // Note: Styles for TextSpans must be explicitly defined.
                                  // Child text spans will inherit styles from parent
                                  style: new TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.black,
                                  ),
                                  children: <TextSpan>[
                                    new TextSpan(
                                        text: menuItems[index].toString(),
                                        style: new TextStyle()),
                                    pincodeList.length > 0 &&
                                        pincodeList[index] != null
                                        ? new TextSpan(
                                        text: ',  ' +
                                            pincodeList[index].toString())
                                        : TextSpan(text: ''),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    })),
          ],
        )));
  }

  void _onTileClicked(int index) {
    // showToast(allList[index]['officename'] + ', ' + allList[index]['districtname']);
    widget.function(menuItems[index].toString(), pharmacyIdList[index], branchIdList[index]);
    Navigator.pop(context);
  }

  Future<Map<String, Object>> searchArea(String are) async {
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      'Content-type': 'application/json',
      "Authorization": 'bearer $token'
    };

    final response = await http.get(RestDatasource.PHARMACY_LIST_URL + "?searchValue=" + are,
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
          if (data == null) {
            // _showSnackBar("No Pharmacy Found");
          } else {
            List<dynamic> homelist = data['list'];
            // Iterable a = json.decode(userType);
            if (homelist.length > 0) {
              if (menuItems != null) menuItems.clear();
              if (pharmacyIdList != null) pharmacyIdList.clear();
              if (branchIdList != null) branchIdList.clear();
              List list1 = List();
              List list2 = List();
              List list3 = List();
              List list4 = List();
              for (int i = 0; i < homelist.length; i++) {
                list1.add(homelist[i]["branchName"].toString());
                list2.add(homelist[i]["pharmacyId"].toString());
                list3.add(homelist[i]["branchId"].toString());
                if (homelist[i]["postalCode"] != null)
                  list4.add(homelist[i]["postalCode"].toString());
              }
              try {
                setState(() {
                  menuItems = list1;
                  pharmacyIdList = list2;
                  branchIdList = list3;
                  if (list4.length > 0) pincodeList = list4;
                });
              } catch (e) {
                print(e);
              }
            }
            /*else {
          _showSnackBar("Pharmacy not Found");
        }*/
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
