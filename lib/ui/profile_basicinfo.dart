import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rounded_date_picker/rounded_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/data/rest_ds.dart';
import 'package:user/presenter/pharmacy_list_presenter.dart';
import 'package:user/ui/login_screen.dart';
import 'package:http/http.dart' as http;

import '../data/AuthState.dart';
import '../data/DatabaseHelper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog/progress_dialog.dart';

import 'main_page.dart';

class ProfileBasicinfo extends StatefulWidget {
  static String tag = 'place_order-screen';

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new ProfileState();
  }
}

class ProfileState extends State<ProfileBasicinfo> {
  BuildContext _ctx;
  Future<File> imageFile;
  double opacity = 0.0;
  var yetToStartColor = const Color(0xFFF8A340);
  String userId, token;
  bool _isLoading = true;
  final formKey = new GlobalKey<FormState>();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String _username,
      fName,
      middleName,
      lastName,
      contactNumber,
      nhsNumber,
      email,
      postalCode,
      address1,
      address2,
      townName;

  ProgressDialog progressDialog;
  Map<String, Object> profiledata;

  PlaceOrderState() {}

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
    token = prefs.getString('token') ?? "";
    userId = prefs.getString('userId') ?? "";
    progressDialog.style(
        message: "Please wait...",
        borderRadius: 4.0,
        backgroundColor: Colors.white);
    fetchData();
  }

  reload() async {
    /*  Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditAddress(
              data: profiledata,
              reload: reload,
            )));*/
    final result = await Navigator.push(
      context,
      // Create the SelectionScreen in the next step.
      MaterialPageRoute(
          builder: (context) => EditAddress(
                data: profiledata,
              )),
    );
    if (result != null) {
      fetchData();
      _showSnackBar("Successfully updated");
      _asyncConfirmDialog() {
        showDialog(
          context: _ctx,
          builder: (context) => new AlertDialog(
            //title: new Text('Are you sure?'),
            content: new Text("Successfully updated"),
            actions: <Widget>[
              new FlatButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: new Text('Close'),
              ),
            ],
          ),
        );
      }
      // Navigator.pop(context, true);
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

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final focus = FocusNode();

    var banner = Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        new Center(
          child: _isLoading
              ? new CircularProgressIndicator()
              : SizedBox(height: 8.0),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 30),
          child: Container(
            //replace this Container with your Card
            color: Colors.white,
            height: 200.0,
            child: Image.asset(
              'assets/profile_banner.png',
              fit: BoxFit.fill,
            ),
          ),
        ),
        Positioned(
            bottom: 0.0,
            right: 0.0,
            left: 0.0,
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Color(0xfff58053),
                          borderRadius: BorderRadius.all(
                            Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey,
                              offset: Offset(0.0, 1.0), //(x,y)
                              blurRadius: 6.0,
                            ),
                          ],
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            _username != null
                                ? '${_username[0].toUpperCase()}'
                                : '',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  ],
                )))
      ],
    );
    var basicinfo = Padding(
      padding: const EdgeInsets.only(top: 2, left: 10, right: 10),
      child: new Card(
          child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: new Column(
                children: [
                  SizedBox(
                    height: 8,
                  ),
                  new Text(
                    _username,
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  new Text(
                    email != null ? email : "",
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  new Text(
                    contactNumber != null ? contactNumber : "",
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  new Text(
                    address1 != null ? address1 : "",
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  new Text(
                    address2 != null ? address2 : "",
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  new Text(
                    townName != null ? townName : "",
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  new Text(
                    postalCode != null ? postalCode : "",
                  ),
                  SizedBox(
                    height: 8,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
              right: 8,
              /* width: 30,
              height: 30,*/
              child: new Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      if (profiledata != null) {
                        reload();
                      } else
                        _showSnackBar("Profile info not found");
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.mode_edit),
                    ),
                  )))
        ],
      )),
    );

    const PrimaryColor = const Color(0xFFffffff);
    const titleColor = const Color(0xFF151026);
    return new Scaffold(
        appBar: AppBar(
          elevation: 0.5,
          centerTitle: true,
          title:
              const Text('MY DETAILS', style: TextStyle(color: Colors.black)),
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
        key: scaffoldKey,
        body: SafeArea(
          child: Column(children: [
            new Expanded(
                child: new ListView(
              children: <Widget>[banner, basicinfo],
            )),
          ]),
        ));
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
        // if (data.containsKey("data")) {pharmacyId, branchId
        if (data == null) {
          _showSnackBar("No Data Found");
        } else {
          profiledata = data;
          print(data.toString());
          var status = data['status'];
          if (status != null && status == true) {
            setState(() {
              if (data['firstName'] != null)
                fName = data['firstName'].toString();
              if (data['middleName'] != null)
                middleName = data['middleName'].toString();
              if (data['lastName'] != null)
                lastName = data['lastName'].toString();
              if (data['contactNumber'] != null)
                contactNumber = data['contactNumber'].toString();
              if (data['nhsNumber'] != null)
                nhsNumber = data['nhsNumber'].toString();
              if (data['email'] != null) email = data['email'].toString();
              if (data['postalCode'] != null)
                postalCode = data['postalCode'].toString();
              if (data['address1'] != null)
                address1 = data['address1'].toString();
              if (data['address2'] != null)
                address2 = data['address2'].toString();
              if (data['townName'] != null)
                townName = data['townName'].toString();
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
}

class EditAddress extends StatefulWidget {
  static String tag = 'signup-page';
  final Map<String, dynamic> data;

  EditAddress({
    this.data,
  });

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new EditAddressState();
  }
}

class EditAddressState extends State<EditAddress> implements PharmacyListCotract {
  int _currVal = 1;
  String _currText = '';
  BuildContext _ctx;
  var yetToStartColor = const Color(0xFFF8A340);
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String userId, token;
  var customerId;
  String fName,
      lName,
      mName,
      contact,
      email,
      nhs,
      pincode,
      pharmacyrid,
      branchId,
      gender,
      dob,
      titleValue;
  String address1, address2, town, landline, alternateContact, dependentContact;
  String surgeryId, surgeryName;
  int correctScore = 0;
  final formKey = new GlobalKey<FormState>();
  ProgressDialog progressDialog;
  List menuItems = List();
  List<String> countryIdList = List();
  String _mySelection, countryid, paymentExemption;
  List paymentMenuItems = List();
  List<String> paymentIdList = List();
  String _paymentSelection, _paymentSelectionId;
  bool _isLoading = false;
  bool isMobileAlreadyAval = false;
  String isMobileAlreadyAvalMessage = "";
  TextEditingController fnameController = TextEditingController();
  TextEditingController mnameController = TextEditingController();
  TextEditingController lnameController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController nhsController = TextEditingController();
  TextEditingController pincodeController = TextEditingController();
  TextEditingController landlineController = TextEditingController();
  TextEditingController alternateController = TextEditingController();
  TextEditingController dependentController = TextEditingController();
  final focuslandline = FocusNode();
  final focusalterContact = FocusNode();
  final focusdepend = FocusNode();
  PharmacyListPresenter _pharmacyListPresenter;
  List<String> pharmacyIdList = List();
  List<String> branchIdList = List();
  final focusfName = FocusNode();
  final focusmName = FocusNode();
  final focuslName = FocusNode();
  final focusContact = FocusNode();
  final focusEmail = FocusNode();
  final focusNhs = FocusNode();
  final focuspostalcode = FocusNode();
  var notdeliveryColor = const Color(0xFFE66363);
  var deliverColor = const Color(0xFF0071BC);
  var deliveredColor = const Color(0xFF4AC66E);

  @override
  void initState() {
    super.initState();
    progressDialog = new ProgressDialog(context);
    progressDialog.style(
        message: "Please wait...",
        borderRadius: 4.0,
        backgroundColor: Colors.white);
    _pharmacyListPresenter = new PharmacyListPresenter(this);
    init();
  }

  void init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token') ?? "";
      userId = prefs.getString('userId') ?? "";
      customerId = prefs.getString('customerId') ?? "";
    if(widget.data != null){
      if (widget.data['firstName'] != null) {
        fName = widget.data['firstName'].toString();
        fnameController.text = fName;
      } else
        fName = "";
      if (widget.data['middleName'] != null) {
        mName = widget.data['middleName'].toString();
        mnameController.text = mName;
      } else
        mName = "";
      if (widget.data['lastName'] != null) {
        lName = widget.data['lastName'].toString();
        lnameController.text = lName;
      } else
        lName = "";
      if (widget.data['contactNumber'] != null) {
        contact = widget.data['contactNumber'].toString();
        contactController.text = contact;
      } else
        contact = "";
      if (widget.data['nhsNumber'] != null) {
        nhs = widget.data['nhsNumber'].toString();
        nhsController.text = nhs;
      } else
        nhs = "";
      if (widget.data['email'] != null)
        email = widget.data['email'].toString();
      else
        email = "";
      if (widget.data['pharmacyId'] != null)
        pharmacyrid = widget.data['pharmacyId'].toString();
      else
        pharmacyrid = "";
      if (widget.data['branchId'] != null)
        branchId = widget.data['branchId'].toString();
      else
        branchId = "";
      if (widget.data['address1'] != null) {
        address1 = widget.data['address1'].toString();
      } else
        address1 = "";
      if (widget.data['address2'] != null) {
        address2 = widget.data['address2'].toString();
      } else
        address2 = "";
      if (widget.data['townName'] != null) {
        town = widget.data['townName'].toString();
      } else
        town = "";
      if (widget.data['dob'] != null)
        dob = widget.data['dob'].toString();
      else
        dob = "";
      if (widget.data['gender'] != null)
        gender = widget.data['gender'].toString();
      else
        gender = "";
      if (widget.data['title'] != null)
        titleValue = widget.data['title'].toString();
      else
        titleValue = "";
      if (widget.data['countryId'] != null)
        countryid = widget.data['countryId'].toString();
      else
        countryid = "";
      if (widget.data['landlineNumber'] != null) {
        landline = widget.data['landlineNumber'].toString();
        landlineController.text = landline;
      }
      else
        landline = "";
      if (widget.data['alternativeContact'] != null) {
        alternateContact = widget.data['alternativeContact'].toString();
        alternateController.text = alternateContact;
      }
      else
        alternateContact = "";
      if (widget.data['dependentContactNumber'] != null) {
        dependentContact = widget.data['dependentContactNumber'].toString();
        dependentController.text = dependentContact;
      }
      else
        dependentContact = "";
      if (widget.data['surgeryId'] != null)
        surgeryId = widget.data['surgeryId'].toString();
      else
        surgeryId = "0";
      if (widget.data['surgeryName'] != null)
        surgeryName = widget.data['surgeryName'].toString();
      else
        surgeryName = "";
      if (widget.data['postalCode'] != null) {
        pincode = widget.data['postalCode'].toString();
        pincodeController.text = pincode;
        _pharmacyListPresenter.doPharmacyList(pincode);
      } else
        pincode = "";
    }
    } catch (e) {
      print(e);
    }
  }

  void _asyncConfirmDialog(String mes) {
    showDialog<ConfirmAction>(
      context: _ctx,
      barrierDismissible: false, // user must tap button for close dialog!
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(mes),
          actions: <Widget>[
            FlatButton(
              child: const Text('Close'),
              onPressed: () async {
                Navigator.pop(_ctx);
              },
            )
          ],
        );
      },
    );
    // progressDialog.show();
  }

  void _submit() {
    final form = formKey.currentState;
    if (fName == null || fName.isEmpty) {
      _showSnackBar('Enter First name');
      return;
    }
    if (lName == null || lName.isEmpty) {
      _showSnackBar('Enter Last name');
      return;
    }
    if (contact == null || contact.isEmpty) {
      _showSnackBar('Enter Contact');
      return;
    }
    if (isMobileAlreadyAval == true) {
      _showSnackBar('Mobile number Already exist');
      return;
    }
    if (nhs == null || nhs.isEmpty) {
      _showSnackBar('Enter NHS ID');
      return;
    }
    if (pincode == null || pincode.isEmpty) {
      _showSnackBar('Enter Postal Code');
      return;
    }
    if (pharmacyrid == null) {
      _asyncConfirmDialog('Select Pharmacy.If pharmacy not fund, change Postal code');
      return;
    }
        //if (form.validate()) {
        try {
          // setState(() => _isLoading = true);
          form.save();
          //_asyncConfirmDialog();
          Map<String, dynamic> dd = {
            "customerId": int.parse(customerId),
            "firstName": fName,
            "middleName": mName,
            "lastName": lName,
            "contactNumber": contact,
            "email": email,
            "nhsNumber": nhs,
            "postalCode": pincode,
            "pharmacyId": int.parse(pharmacyrid),
            "branchId": int.parse(branchId),
            "gender": gender,
            "dob": dob,
            "title": titleValue,
            "countryId": int.parse(countryid),
            "address1": address1,
            "address2": address2,
            "townName": town,
            "paymentExemption": _paymentSelection,
            "landlineNumber": landline,
            "alternativeContact": alternateContact,
            "dependentContactNumber": dependentContact,
            "surgeryId": int.parse(surgeryId),
            "surgeryName": ""
          };
          setState(() {
            _isLoading = true;
          });
          updateApi(dd);
          //_presenter.doSignup(dd);
        } catch (e) {
          print(e);
        }
        //}
  }

  Future<Map<String, Object>> updateApi(Map<String, dynamic> map) async {
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      "Content-type": "application/json",
      "Authorization": 'bearer $token'
    };
    final j = json.encode(map);
    final response = await http.post(RestDatasource.UPDATE_PROFILE_URL,
        body: j, headers: headers);
    final String res = response.body;
    final int statusCode = response.statusCode;
    setState(() {
      _isLoading = false;
    });
    if (response.statusCode == 200) {
      Map<String, Object> data = json.decode(response.body);
      var status = data['status'];
      var uName = data['message'];
      try {
        if (status == true) {
          Navigator.pop(context, 'Yep!');
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

  @override
  Widget build(BuildContext context) {
    String _user;
    _ctx = context;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    // Fluttertoast.showToast(msg: "signup",toastLength: Toast.LENGTH_LONG);

    var loginForm = new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Form(
          key: formKey,
          child: new Column(children: <Widget>[
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => fName = val,
                    validator: (val) {
                      return val.trim().isEmpty ? "Enter First Name" : null;
                    },
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: false,
                    controller: fnameController,
                    onChanged: (_ctx) {
                      if (fnameController.text != null &&
                          fnameController.text.length > 0)
                        fName = fnameController.text;
                    },
                    decoration: new InputDecoration(
                        labelText: "First Name",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focusfName);
                    },
                  ),
                )),
            new Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                height: 45,
                child: new TextFormField(
                  onSaved: (val) => mName = val,
                  keyboardType: TextInputType.visiblePassword,
                  focusNode: focusfName,
                  controller: mnameController,
                  onChanged: (_ctx) {
                    if (mnameController.text != null &&
                        mnameController.text.length > 0) mName = mnameController.text;
                  },
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                  // initialValue: "Pdm@12345",
                  decoration: new InputDecoration(
                      labelText: "Middle Name",
                      border: new OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                              const Radius.circular(5.0)))),
                  onFieldSubmitted: (v) {
                    FocusScope.of(context).requestFocus(focusmName);
                  },
                ),
              ),
            ),
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => lName = val,
                    keyboardType: TextInputType.visiblePassword,
                    focusNode: focusmName,
                    controller: lnameController,
                    onChanged: (_ctx) {
                      if (lnameController.text != null &&
                          lnameController.text.length > 0)
                        lName = lnameController.text;
                    },
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                    // initialValue: "Pdm@12345",
                    decoration: new InputDecoration(
                        labelText: "Last Name",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focuslName);
                    },
                  ),
                )),
          new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => contact = val,
                    keyboardType: TextInputType.number,
                    focusNode: focuslName,
                    controller: contactController,
                    onChanged: (_ctx) {
                      if (contactController.text != null &&
                          contactController.text.length > 0) {
                        contact = contactController.text;
                        checkMobile(contact);
                      }
                    },
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                    // initialValue: "Pdm@12345",
                    decoration: new InputDecoration(
                        labelText: "Contact Number",
                        errorText: validateMobile(isMobileAlreadyAvalMessage),
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focusContact);
                    },
                  ),
                )),
               new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => nhs = val,
                    keyboardType: TextInputType.visiblePassword,
                    focusNode: focusEmail,
                    controller: nhsController,
                    onChanged: (_ctx) {
                      if (nhsController.text != null &&
                          nhsController.text.length > 0)
                        nhs = nhsController.text;
                    },
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                    // initialValue: "Pdm@12345",
                    decoration: new InputDecoration(
                        labelText: "NHS ID",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focusNhs);
                    },
                  ),
                )),
            new Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  height: 45,
                  child: new TextFormField(
                    onSaved: (val) => () {
                      pincode = val;
                    },
                    controller: pincodeController,
                    onChanged: (_ctx) {
                      if (pincodeController.text != null &&
                          pincodeController.text.length >= 6) {
                        pincode = pincodeController.text;
                        setState(() {
                          _isLoading = true;
                        });
                        _pharmacyListPresenter.doPharmacyList(pincode);
                      }
                    },
                    keyboardType: TextInputType.text,
                    // keyboardType: TextInputType.numberWithOptions(decimal: true),
                    textCapitalization: TextCapitalization.characters,
                    focusNode: focusNhs,
//                validator: (val) {
//                  return val.trim().isEmpty ? "Enter Middle Name" : null;
//                },
                    // initialValue: "Pdm@12345",
                    decoration: new InputDecoration(
                        labelText: "Postal Code",
                        border: new OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0)))),
                    onFieldSubmitted: (v) {
                      FocusScope.of(context).requestFocus(focuspostalcode);
                    },
                  ),
                )),
              new Center(
              child: _isLoading
                  ? new CircularProgressIndicator()
                  : SizedBox(height: 8.0),
            ),
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
                                    "Select Pharmacy",
                                    style: TextStyle(
                                      color: Colors.black45,
                                    ),
                                  ),
                                  onChanged: (newVal) {
                                    setState(() {
                                      _mySelection = newVal;
                                      try {
                                        for (int i = 0;
                                            i < menuItems.length;
                                            i++) {
                                          if (menuItems[i].toString() ==
                                              _mySelection) {
                                            pharmacyrid = pharmacyIdList[i];
                                            branchId = branchIdList[i];
                                            break;
                                          }
                                        }
                                      } catch (e) {
                                        print(e);
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
                    onSaved: (val) => landline = val,
                    validator: (val) {
                      return val.trim().isEmpty ? "Landline Number" : null;
                    },
                    focusNode: focuspostalcode,
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
                )),
            /*  new Row(
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
                                child: DropdownButton<String>(
                                  value: gender,
                                  icon: Icon(Icons.arrow_drop_down),
                                  iconSize: 24,
                                  elevation: 16,
                                  style: TextStyle(color: Colors.black),
                                  underline: SizedBox(),
                                  onChanged: (String newValue) {
                                    setState(() {
                                      gender = newValue;
                                    });
                                  },
                                  items: <String>[
                                    'M',
                                    'F',
                                  ].map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    );
                                  }).toList(),
                                  hint: Text(
                                    "Select Gender",
                                    style: TextStyle(
                                      color: Colors.black45,
                                    ),
                                  ),
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
                                child: DropdownButton<String>(
                                  value: titleValue,
                                  icon: Icon(Icons.arrow_drop_down),
                                  iconSize: 24,
                                  elevation: 16,
                                  style: TextStyle(color: Colors.black),
                                  underline: SizedBox(),
                                  onChanged: (String newValue) {
                                    setState(() {
                                      titleValue = newValue;
                                    });
                                  },
                                  items: <String>[
                                    'Mr',
                                    'Mrs',
                                  ].map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    );
                                  }).toList(),
                                  hint: Text(
                                    "Select Title",
                                    style: TextStyle(
                                      color: Colors.black45,
                                    ),
                                  ),
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
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                        ),
                      ),
                      child: InkResponse(
                        onTap: () async {
                          var formatter = new DateFormat('yyyy-MM-dd');
                          DateTime newDateTime = await showRoundedDatePicker(
                            context: context,
                            initialDate: DateTime(DateTime.now().year - 20),
                            firstDate: DateTime(DateTime.now().year - 99),
                            lastDate: DateTime.now(),
                            initialDatePickerMode: DatePickerMode.year,
                            theme: ThemeData(primarySwatch: Colors.deepOrange),
                          );
                          if (newDateTime != null) {
                            setState(() => dob = formatter.format(newDateTime));
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            dob,
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  flex: 1,
                )
              ],
            ),*/
            /* showImage(),
            RaisedButton(
              child: Text("Select Image from Gallery"),
              onPressed: () {
                pickImageFromGallery(ImageSource.gallery);
              },
            ),*/
          ]),
        ),
        // _isLoading ? new CircularProgressIndicator() : SizedBox(height: 8.0),
      ],
    );

    final loginButton = Padding(
        padding: EdgeInsets.all(16.0),
        child: new ButtonTheme(
          minWidth: 230,
          height: 45,
          child: new RaisedButton(
            onPressed: _submit,
            child: new Text("Submit"),
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
        title: const Text('UPDATE MY DETAILS',
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
            !_isLoading ? loginButton : SizedBox(height: 8.0),
            new Center(
              child: _isLoading
                  ? new CircularProgressIndicator()
                  : SizedBox(height: 8.0),
            ),
          ],
        ),
      ),
    );
  }

  String validateMobile(String value) {
    if (value.isNotEmpty) {
      return "Mobile Already exist";
    }
    return null;
  }

  Future<Map<String, Object>> checkMobile(String mob) async {
    final JsonDecoder _decoder = new JsonDecoder();
    Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-type': 'application/json',
    };

    final response = await http.get(
        RestDatasource.CHECK_MOBILE_VALIDATION_URL + mob,
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
        // if (data.containsKey("data")) {
        if (data == null) {
          _showSnackBar("No Data Found");
        } else {
          print(data.toString());
          var status = data['status'];
          var uName = data['message'];
          try {
            if (status == true) {
              setState(() {
                isMobileAlreadyAval = false;
                isMobileAlreadyAvalMessage = "";
              });
            } else {
              setState(() {
                isMobileAlreadyAval = true;
                isMobileAlreadyAvalMessage = uName;
              });
            }
          } catch (e) {
            _showSnackBar(e);
          }
        }
      } catch (e) {
        _showSnackBar(e);
      }
    } else if (response.statusCode == 401) {
      _showSnackBar('Something went wrong');
    } else {
      _showSnackBar('Something went wrong');
    }
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
        fontSize: 16.0);
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

  @override
  void onPharmacyListError(String errorTxt) {
    progressDialog.hide();
    _showSnackBar(errorTxt);
    setState(() => _isLoading = false);
  }

  @override
  void onPharmacyListSuccess(Map<String, Object> data) {
    progressDialog.hide();
    setState(() => _isLoading = false);
    try {
      // if (data.containsKey("data")) {
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
          try {
            setState(() {
              for (int i = 0; i < homelist.length; i++) {
                menuItems.add(homelist[i]["branchName"].toString());
                pharmacyIdList.add(homelist[i]["pharmacyId"].toString());
                branchIdList.add(homelist[i]["branchId"].toString());
              }
              /*  menuItems = list1;
              pharmacyIdList = list2;
              branchIdList = list3;*/
            });
          } catch (e) {
            print(e);
          }
        }
        /*else {
          _showSnackBar("Pharmacy not Found");
        }*/
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
