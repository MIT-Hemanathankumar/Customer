import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/data/rest_ds.dart';
import 'package:user/ui/main_page.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';

class ChangePassword extends StatefulWidget {
  // Declare a field that holds the Todo.

  // In the constructor, require a Todo.
  ChangePassword();

  @override
  ChangePasswordState createState() => ChangePasswordState();
}

class ChangePasswordState extends State<ChangePassword> {
  var yetToStartColor = const Color(0xFFF8A340);
  var blue = const Color(0xFF2188e5);
  String userId, token, customerId;
  ProgressDialog progressDialog;
  final focusfMedicine = FocusNode();
  final focuslStrenght = FocusNode();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();
  bool _passobscureText = true;
  bool _confrimpassobscureText = true;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String _password, _confirmPass;
  static final validCharacters = RegExp(r'^[a-zA-Z0-9_\-=@,\.;]+$');

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    super.dispose();
  }

  void init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? "";
    userId = prefs.getString('userId') ?? "";
    customerId = prefs.getString('customerId') ?? "";
    progressDialog = new ProgressDialog(context);
    progressDialog.style(
        message: "Please wait...",
        borderRadius: 4.0,
        backgroundColor: Colors.white);
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    const gray = const Color(0xFFEEEFEE);
    double c_width = MediaQuery.of(context).size.width * 0.6;
    return WillPopScope(
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0.5,
            backgroundColor: Colors.white,
            brightness: Brightness.light,
            iconTheme: IconThemeData(
              color: Colors.black, //c// hange your color here
            ),
            centerTitle: true,
            title: const Text('SET PASSWORD',
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
                            Form(
                              key: formKey,
                              child: new Column(children: <Widget>[
                                new Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Container(
                                      height: 50,
                                      color: Colors.white,
                                      child: new TextFormField(
                                        onSaved: (val) => _password = val,
                                        validator: (val) {
                                          return val.trim().isEmpty
                                              ? "Password"
                                              : null;
                                        },
                                        //initialValue: "",
                                        textInputAction: TextInputAction.next,
                                        keyboardType: TextInputType.visiblePassword,
                                        autofocus: false,
                                        obscureText: _passobscureText,
                                        controller: passwordController,
                                        onChanged: (_ctx) {
                                          if (passwordController.text != null &&
                                              passwordController.text.length > 0)
                                            _password =
                                                passwordController.text;
                                        },
                                        decoration: InputDecoration(
                                          border: new OutlineInputBorder(
                                              borderRadius: const BorderRadius.all(
                                                  const Radius.circular(5.0))),
                                          filled: true,
                                          hintText: "Password",
                                          labelText: "Password",
                                          suffixIcon: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _passobscureText = !_passobscureText;
                                              });
                                            },
                                            child: Icon(_passobscureText ? Icons.visibility : Icons.visibility_off),
                                          ),
                                        ),
                                        onFieldSubmitted: (v) {
                                          FocusScope.of(context)
                                              .requestFocus(focusfMedicine);
                                        },
                                      ),
                                    )),
                                new Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Container(
                                      color: Colors.white,
                                      height: 50,
                                      child: new TextFormField(
                                        onSaved: (val) => _confirmPass = val,
                                        validator: (val) {
                                          return val.trim().isEmpty
                                              ? "Confirm Password"
                                              : null;
                                        },
                                        //initialValue: "",
                                        textInputAction: TextInputAction.next,
                                        keyboardType: TextInputType.visiblePassword,
                                        focusNode: focusfMedicine,
                                        autofocus: false,
                                        obscureText: _confrimpassobscureText,
                                        controller: confirmPassController,
                                        onChanged: (_ctx) {
                                          if (confirmPassController.text != null &&
                                              confirmPassController.text.length > 0)
                                            _confirmPass = confirmPassController.text;
                                        },
                                        decoration: InputDecoration(
                                          border: new OutlineInputBorder(
                                              borderRadius: const BorderRadius.all(
                                                  const Radius.circular(5.0))),
                                          filled: true,
                                          hintText: "Confirm Password",
                                          labelText: "Confirm Password",
                                          suffixIcon: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _confrimpassobscureText = !_confrimpassobscureText;
                                              });
                                            },
                                            child: Icon(_confrimpassobscureText ? Icons.visibility : Icons.visibility_off),
                                          ),
                                        ),
                                        onFieldSubmitted: (v) {
                                          FocusScope.of(context)
                                              .requestFocus(focuslStrenght);
                                        },
                                      ),
                                    )),
                              ]),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: new Text(
                                'Password Should contain a-z, A-Z, 0-9, _\-=@,\.;]+',
                                style:
                                    TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ),
                            new Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: new ButtonTheme(
                                    minWidth: 230,
                                    height: 45,
                                    child: new RaisedButton(
                                      onPressed: () {
                                        if (_password == null) {
                                          _showSnackBar("Enter Password");
                                          return;
                                        }
                                        if (_confirmPass == null) {
                                          _showSnackBar(
                                              "Enter Confirm Password");
                                          return;
                                        }
                                        if (_confirmPass != _password) {
                                          _showSnackBar(
                                              "Password Confirm Password not matching");
                                          return;
                                        }
                                        if (validCharacters
                                            .hasMatch(_password)) {
                                          progressDialog.show();
                                          changePass();
                                        } else {
                                          _showSnackBar(
                                              "Password missing charc");
                                        }
                                      },
                                      child: new Text("Submit"),
                                      color: yetToStartColor,
                                      textColor: Colors.white,
                                    ))),
                            // _isLoading ? new CircularProgressIndicator() : SizedBox(height: 8.0),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )),
      onWillPop: _onWillPop,
    );
  }

  Future<Map<String, Object>> changePass() async {
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      "Content-type": "application/json",
      "Authorization": 'bearer $token'
    };
    Map<String, dynamic> data = {
      "password": _password,
      "customerId": int.parse(customerId),
    };
    final j = json.encode(data);
    final response = await http.post(RestDatasource.CHANGE_PASSWORD_LIST_URL,
        body: j, headers: headers);
    progressDialog.hide();
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
          var status = data['status'];
          var uName = data['message'];
          if (status == true) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => Home(),
                ),
                ModalRoute.withName('/login_screen'));
          } else {
            _showSnackBar(uName);
          }
        }
      } catch (e) {
        _showSnackBar(e);
      }
    } else if (response.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('token');
      prefs.remove('userId');
      prefs.remove('customerId');
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

  void _submit() {
    // deliveryName = deliveryToController.text.toString();
    // remarks = remarkController.text.toString();
  }

  void _showSnackBar(String text) {
    Fluttertoast.showToast(msg: text, toastLength: Toast.LENGTH_LONG);
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text('Are you sure?'),
            content: new Text('Do you want to exit from set password'),
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
