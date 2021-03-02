import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/data/DatabaseHelper.dart';
import 'package:user/data/rest_ds.dart';
import 'package:user/presenter/country_list_presenter.dart';
import 'package:user/presenter/login_screen_presenter.dart';
import 'package:user/presenter/signup_screen_presenter.dart';
import 'package:user/ui/change_password.dart';
import 'package:user/ui/main_page.dart';
import 'package:http/http.dart' as http;

class SignupPage extends StatefulWidget {
  static String tag = 'signup-page';
  final String fName,
      lName,
      mName,
      contact,
      email,
      nhs,
      pincode,
      pharmacyrid,
      branchId,
      gender,
      dob, titleValue;
  final String surgeryOption, nhsExemptionOption;

  SignupPage(
      {this.fName,
      this.lName,
      this.mName,
      this.contact,
      this.email,
      this.nhs,
      this.pincode,
      this.pharmacyrid,
      this.branchId,
      this.gender,
      this.dob,
        this.surgeryOption, this.nhsExemptionOption,
        this.titleValue});

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new SignupPageState();
  }
}

class SignupPageState extends State<SignupPage>
    implements SignupScreenContract, CountryListCotract {
  int _currVal = 1;
  String _currText = '';
  BuildContext _ctx;
  var yetToStartColor = const Color(0xFFF8A340);
  final scaffoldKey = new GlobalKey<ScaffoldState>();

  int correctScore = 0;
  final formKey = new GlobalKey<FormState>();
  SignupScreenPresenter _presenter;
  ProgressDialog progressDialog;
  CountryListPresenter _countryListPresenter;
  List menuItems = List();
  List<String> countryIdList = List();
  String _mySelection, countryid;
  List paymentMenuItems = List();
  List<String> paymentIdList = List();
  String _paymentSelection, _paymentSelectionId;
  final focusAddress1 = FocusNode();
  final focusAddress2 = FocusNode();
  final focustown = FocusNode();
  final focuslandline = FocusNode();
  final focusalterContact = FocusNode();
  final focusdepend = FocusNode();
  TextEditingController address1Controller = TextEditingController();
  TextEditingController address2Controller = TextEditingController();
  TextEditingController townController = TextEditingController();
  TextEditingController landlineController = TextEditingController();
  TextEditingController alternateController = TextEditingController();
  TextEditingController dependentController = TextEditingController();
  TextEditingController pincodeController = TextEditingController();
  String address1, address2, town, landline, alternateContact, dependentContact;

  SignupPageState() {
    _presenter = new SignupScreenPresenter(this);
    _countryListPresenter = new CountryListPresenter(this);
    progressDialog = new ProgressDialog(context);
    progressDialog.style(
        message: "Please wait...",
        borderRadius: 4.0,
        backgroundColor: Colors.white);
    init();

  }

  @override
  void initState() {
    super.initState();
  }

  void init() async {
    try {
      progressDialog.show();
      fetchCountry();
      fetchPayment();
    } catch (e) {
      print(e);
    }
  }

  Future<Map<String, Object>> fetchCountry() async {
    final JsonDecoder _decoder = new JsonDecoder();
    final response = await http
        .get(RestDatasource.COUNTRY_URL);

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
          if (menuItems != null) menuItems.clear();
          if (countryIdList != null) countryIdList.clear();
          // Iterable a = json.decode(userType);countryName, countryId
          // List<GroupModel> homelist = a.map((model) => GroupModel.fromJson(model)).toList();
          if (homelist.length > 0) {
            setState(() {
              for (int i = 0; i < homelist.length; i++) {
                menuItems.add(homelist[i]["countryName"].toString());
                countryIdList.add(homelist[i]["countryId"].toString());
              }
            });
          } else {
            _showSnackBar("No Data Found");
          }
        }
      } catch (e) {
        _showSnackBar(e);
      }
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }

  Future<Map<String, Object>> fetchPayment() async {
    final JsonDecoder _decoder = new JsonDecoder();
    final response = await http.get(RestDatasource.PAYMENT_EXEMPTION_URL);

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Map<String, Object> data = json.decode(response.body);
      progressDialog.hide();
      try {
        // if (data.containsKey("data")) {
        if (data == null) {
         // _showSnackBar("No Data Found");
        } else {
          print(data.toString());
          List<dynamic> homelist = data['list'];
          if (paymentMenuItems != null) paymentMenuItems.clear();
          if (paymentIdList != null) paymentIdList.clear();
          // Iterable a = json.decode(userType);countryName, countryId
          // List<GroupModel> homelist = a.map((model) => GroupModel.fromJson(model)).toList();
          if (homelist.length > 0) {
            setState(() {
              for (int i = 0; i < homelist.length; i++) {
                paymentMenuItems.add(homelist[i]["description"].toString());
                paymentIdList.add(homelist[i]["paymentExemptionId"].toString());
              }
            });
          } else {
            //_showSnackBar("No Data Found");
          }
        }
      } catch (e) {
        _showSnackBar(e);
      }
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }

  void _submit() {
    final form = formKey.currentState;
    if (address1 == null) {
      _showSnackBar('Enter House No');
      return;
    }
    if (address2 == null) {
      _showSnackBar('Enter Address');
      return;
    }
    if (town == null) {
      _showSnackBar('Enter Town');
      return;
    }
    if (pincodeController.text == '') {
      _showSnackBar('Enter Postcode');
      return;
    }
   /* if (landline == null) {
      _showSnackBar('Enter Landline');
      return;
    }
    if (alternateContact == null) {
      _showSnackBar('Enter Alternate Contact');
      return;
    }
    if (dependentContact == null) {
      _showSnackBar('Enter Dependent Contact');
      return;
    }*/
    if (countryid != null && countryid.isNotEmpty) {
     // if (_paymentSelectionId != null && _paymentSelectionId.isNotEmpty) {
        //if (form.validate()) {
          try {
            progressDialog.show();
            // setState(() => _isLoading = true);
           // form.save();
            //_asyncConfirmDialog();
            Map<String, dynamic> dd = {
              "firstName": widget.fName,
              "middleName": widget.mName,
              "lastName": widget.lName,
              "contactNumber": widget.contact,
              "email": widget.email,
              "nhsNumber": widget.nhs,
              "postalCode": pincodeController.text,
              "pharmacyId": int.parse(widget.pharmacyrid),
              "branchId": int.parse(widget.branchId),
              "gender": widget.gender,
              "dob": widget.dob,
              "title": widget.titleValue,
              "countryId": int.parse(countryid),
              "address1": address1,
              "address2": address2,
              "townName": town,
              "paymentExemption": _paymentSelection,
              "landlineNumber": landline,
              "alternativeContact": alternateContact,
              "dependentContactNumber": dependentContact,
              "surgeryId": int.parse(widget.surgeryOption),
              "paymentExemption": widget.nhsExemptionOption
            };
            signupApi(dd);
            //_presenter.doSignup(dd);
          } catch (e) {
            print(e);
          }
        //}
      /*} else {
        _showSnackBar('Select Payment Exemptions');
      }*/
    } else {
      _showSnackBar('Select Country');
    }
  }

  Future<Map<String, Object>> signupApi(Map<String, dynamic> map) async {
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-type' : 'application/json'
    };
    final j = json.encode(map);
    final response = await http.post(RestDatasource.SIGNUP_URL,
        body: j, headers: headers);
      final String res = response.body;
      final int statusCode = response.statusCode;
    progressDialog.hide();
    print(json.decode(response.body).toString());
      if (response.statusCode == 200) {
        Map<String, Object> data = json.decode(response.body);
        var status = data['status'];
        var uName = data['message'];

        try {
          if (status == true) {
            String userId = data['userId'].toString();
            String customerId = data['customerId'].toString();
            String token = data['token'].toString();
            String name = data['name'].toString();
            String email = data['email'].toString();
            String mobile = data['mobile'].toString();
            final prefs = await SharedPreferences.getInstance();
            //  prefs.setString('token', token);
            prefs.setString('userId', userId);
            prefs.setString('customerId', customerId);
            prefs.setString('token', token);
            prefs.setString('name', name);
            prefs.setString('email', email);
            prefs.setString('mobile', mobile);
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => ChangePassword(),
                ),
                ModalRoute.withName('/login_screen'));
            /* var authStateProvider = new AuthStateProvider();
                    authStateProvider.notify(AuthState.LOGGED_IN);*/
            // _showSnackBar("Login success");
          } else {
            _showSnackBar(uName);
          }
        } catch (e) {
          _showSnackBar(e.toString());
        }
      } else if (response.statusCode == 401) {
        _showSnackBar('Session expired, try again');
      } else {
        _showSnackBar('Something went wrong');
      }
  }

  void _asyncConfirmDialog() {
   /* showDialog<ConfirmAction>(
      context: context,
      barrierDismissible: false, // user must tap button for close dialog!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text(dd.toString()),
          actions: <Widget>[
            FlatButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.pop(_ctx);
              },
            ),
          ],
        );
      },
    );*/
   // progressDialog.show();
  }

  @override
  Widget build(BuildContext context) {
    String _user;
    _ctx = context;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    // Fluttertoast.showToast(msg: "signup",toastLength: Toast.LENGTH_LONG);

    var loginForm =
        new Column(mainAxisAlignment: MainAxisAlignment.center, children: <
            Widget>[
      new Form(
        key: formKey,
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 20,
            ),
            Center(
              child: Text('YOUR ADDRESS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 16,
                  )),
            ),
            SizedBox(
              height: 20,
            ),
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => address1 = val,
                    validator: (val) {
                      return val.trim().isEmpty ? "House No" : null;
                    },
                    controller: address1Controller,
                    onChanged: (_ctx) {
                      if (address1Controller.text != null &&
                          address1Controller.text.length > 0)
                        address1 = address1Controller.text;
                    },
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: false,
                    decoration: new InputDecoration(
                        labelText: "House No",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focusAddress1);
                    },
                  ),
                )),
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => address2 = val,
                    textInputAction: TextInputAction.next,
                    focusNode: focusAddress1,
                    keyboardType: TextInputType.text,
                    autofocus: false,
                    controller: address2Controller,
                    onChanged: (_ctx) {
                      if (address2Controller.text != null &&
                          address2Controller.text.length > 0)
                        address2 = address2Controller.text;
                    },
                    decoration: new InputDecoration(
                        labelText: "First Line of Address",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focusAddress2);
                    },
                  ),
                )),
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => town = val,
                    validator: (val) {
                      return val.trim().isEmpty ? "Town" : null;
                    },
                    focusNode: focusAddress2,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.text,
                    autofocus: false,
                    controller: townController,
                    onChanged: (_ctx) {
                      if (townController.text != null &&
                          townController.text.length > 0)
                        town = townController.text;
                    },
                    decoration: new InputDecoration(
                        labelText: "Town",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focustown);
                    },
                  ),
                )),
            new Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                        height: 45,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                                width: 1.0,
                                style: BorderStyle.solid,
                                color: Colors.grey),
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0)),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                child: DropdownButton(
                                  underline: SizedBox(),
                                  items: menuItems.map((item) {
                                    return new DropdownMenuItem(
                                      child: new Text(
                                        item.toString(),
                                        style: TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.black),
                                      ),
                                      value: item.toString(),
                                    );
                                  }).toList(),
                                  hint: Text(
                                    "Select Country",
                                    style: TextStyle(
                                      color: Colors.black45,
                                    ),
                                  ),
                                  onChanged: (newVal) {
                                    setState(() {
                                      _mySelection = newVal;
                                      for (int i = 0;
                                          i < menuItems.length;
                                          i++) {
                                        if (menuItems[i].toString() ==
                                            _mySelection) {
                                          countryid = countryIdList[i];
                                        }
                                      }
                                    });
                                  },
                                  value: _mySelection,
                                ),
                              ),
                              flex: 1,
                            ),
                          ],
                        )),
                  ),
                  flex: 1,
                )
              ],
            ),
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    controller: pincodeController,
                    keyboardType: TextInputType.text,
                    // keyboardType: TextInputType.numberWithOptions(decimal: true),
                    textCapitalization: TextCapitalization.characters,
                    focusNode: focustown,
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                    // initialValue: "Pdm@12345",
                    decoration: new InputDecoration(
                        labelText: "Postal Code",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                  ),
                )),
            /*new Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                        height: 45,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                                width: 1.0,
                                style: BorderStyle.solid,
                                color: Colors.grey),
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0)),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                child: DropdownButton(
                                  underline: SizedBox(),
                                  items: paymentMenuItems.map((item) {
                                    return new DropdownMenuItem(
                                      child: new Text(
                                        item.toString(),
                                        style: TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.black),
                                      ),
                                      value: item.toString(),
                                    );
                                  }).toList(),
                                  hint: Text(
                                    "Select Payment Exemptions type",
                                    style: TextStyle(
                                      color: Colors.black45,
                                    ),
                                  ),
                                  onChanged: (newVal) {
                                    setState(() {
                                      _paymentSelection = newVal;
                                      for (int i = 0;
                                          i < paymentMenuItems.length;
                                          i++) {
                                        if (paymentMenuItems[i].toString() ==
                                            _paymentSelection) {
                                          _paymentSelectionId =
                                              paymentIdList[i];
                                        }
                                      }
                                    });
                                  },
                                  value: _paymentSelection,
                                ),
                              ),
                              flex: 1,
                            ),
                          ],
                        )),
                  ),
                  flex: 1,
                )
              ],
            ),
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => landline = val,
                    validator: (val) {
                      return val.trim().isEmpty ? "Landline Number" : null;
                    },
                    focusNode: focustown,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    autofocus: false,
                    controller: landlineController,
                    onChanged: (_ctx) {
                      if (landlineController.text != null &&
                          landlineController.text.length > 0)
                        landline = landlineController.text;
                    },
                    decoration: new InputDecoration(
                        labelText: "Landline Number",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focuslandline);
                    },
                  ),
                )),
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => alternateContact = val,
                    validator: (val) {
                      return val.trim().isEmpty
                          ? "Alternate Contact Number"
                          : null;
                    },
                    focusNode: focuslandline,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    autofocus: false,
                    controller: alternateController,
                    onChanged: (_ctx) {
                      if (alternateController.text != null &&
                          alternateController.text.length > 0)
                        alternateContact = alternateController.text;
                    },
                    decoration: new InputDecoration(
                        labelText: "Alternate Contact Number",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focusalterContact);
                    },
                  ),
                )),
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => dependentContact = val,
                    validator: (val) {
                      return val.trim().isEmpty
                          ? "Dependent Contact Number"
                          : null;
                    },
                    focusNode: focusalterContact,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    autofocus: false,
                    controller: dependentController,
                    onChanged: (_ctx) {
                      if (dependentController.text != null &&
                          dependentController.text.length > 0)
                        dependentContact = dependentController.text;
                    },
                    decoration: new InputDecoration(
                        labelText: "Dependent Contact Number",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focusdepend);
                    },
                  ),
                )),*/
          ],
        ),
      )
    ]);

    final loginButton = Padding(
        padding: EdgeInsets.all(16.0),
        child: new ButtonTheme(
          minWidth: 230,
          height: 45,
          child: new RaisedButton(
            onPressed: _submit,
            child: new Text("SIGN UP"),
            color: yetToStartColor,
            textColor: Colors.white,
          ),
        ));

    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        brightness: Brightness.light,
        iconTheme: IconThemeData(
          color: Colors.black, //c// hange your color here
        ),
        centerTitle: true,
        title: const Text('COMPLETE REGISTRATION',
            style: TextStyle(color: Colors.black)),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, false);
            }),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SizedBox(height: 20.0),
            loginForm,
            SizedBox(height: 24.0),
            loginButton,
          ],
        ),
      ),
    );
  }

  @override
  void onSignupError(String errorTxt) {
    _showSnackBar(errorTxt);
    progressDialog.hide();
    //setState(() => _isLoading = false);
  }

  void _showSnackBar(String text) {
   // scaffoldKey.currentState
     //   .showSnackBar(new SnackBar(content: new Text(text)));
    Fluttertoast.showToast(
        msg: text,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  @override
  void onSignupSuccess(Map<String, Object> user) async {
    progressDialog.hide();
    var db = new DatabaseHelper();
    var status = user['status'];
    var uName = user['message'];

    try {
      if (status == true) {
        String userId = user['userId'].toString();
        String customerId = user['customerId'].toString();
        String token = user['token'].toString();
       // String token = user['token'].toString();
       // String name = user['name'].toString();
       // String email = user['email'].toString();
       // String mobile = user['mobile'].toString();
        // await db.saveUser(u);
        final prefs = await SharedPreferences.getInstance();
      //  prefs.setString('token', token);
        prefs.setString('userId', userId);
        prefs.setString('customerId', customerId);
        prefs.setString('token', token);

      //  prefs.setString('name', name);
       // prefs.setString('email', email);
       // prefs.setString('mobile', mobile);
        // Navigator.of(_ctx).pushNamed(HomePage.tag);
        // Navigator.push(_ctx, MaterialPageRoute(builder: (context) => HomePage()));
       /* Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => Home(),
            ),
            ModalRoute.withName('/login_screen'));*/

        /* var authStateProvider = new AuthStateProvider();
                    authStateProvider.notify(AuthState.LOGGED_IN);*/
        // _showSnackBar("Login success");
      } else {
        _showSnackBar(uName);
      }
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }

  @override
  void onCountryListError(String errorTxt) {
    progressDialog.hide();
    _showSnackBar(errorTxt);
  }

  @override
  Future<void> onCountryListSuccess(Map<String, Object> data) async {
    progressDialog.hide();
    try {
      // if (data.containsKey("data")) {
      if (data == null) {
        _showSnackBar("No Data Found");
      } else {
        print(data.toString());
        List<dynamic> homelist = data['list'];
        if (menuItems != null) menuItems.clear();
        if (countryIdList != null) countryIdList.clear();
        // Iterable a = json.decode(userType);countryName, countryId
        // List<GroupModel> homelist = a.map((model) => GroupModel.fromJson(model)).toList();
        if (homelist.length > 0) {
          setState(() {
            for (int i = 0; i < homelist.length; i++) {
              menuItems.add(homelist[i]["countryName"]);
              countryIdList.add(homelist[i]["countryId"]);
            }
          });
        } else {
          _showSnackBar("No Data Found");
        }
      }
    } catch (e) {
      _showSnackBar(e);
    }
  }
}

class GroupModel {
  String text;
  int index;

  GroupModel({this.text, this.index});
}
